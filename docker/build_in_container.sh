#/bin/bash

_cpu_count="$(nproc)"

echo "LOCAL_REPO_DIR: $LOCAL_REPO_DIR"
echo "QNN_SDK_PATH: $QNN_SDK_PATH"
echo "HEXAGON_SDK_PATH: $HEXAGON_SDK_PATH"
echo "GGML_HEXAGON: $GGML_HEXAGON"
echo "BUILD_HEXAGON_BACKEND: $BUILD_HEXAGON_BACKEND"
echo "BUILD_HEXAGON_NPU_ONLY: $BUILD_HEXAGON_NPU_ONLY"
echo "DISABLE_HEXAGON_AND_QNN: $DISABLE_HEXAGON_AND_QNN"
echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
echo "TARGET_PLATFORM: $TARGET_PLATFORM"
echo "TARGET_ARCH: $TARGET_ARCH"
echo "ANDROID_API_LEVEL: $ANDROID_PLATFORM"
echo "BUILD_TYPE: $BUILD_TYPE"
echo "CPU_COUNT: $_cpu_count"
echo "CMAKE_EXTRA_BUILD_OPTIONS: $CMAKE_EXTRA_BUILD_OPTIONS"

if [ -z "$QNN_SDK_PATH" ]; then
    echo "QNN_SDK_PATH is not set"
    exit 1
fi

if [ -z "$TARGET_ARCH" ]; then
    echo "TARGET_ARCH is not set"
    exit 1
fi

source $QNN_SDK_PATH/bin/envsetup.sh

if [ ! -z "$HEXAGON_SDK_PATH" ]; then
    source $HEXAGON_SDK_PATH/setup_sdk_env.source
fi

# Sync the source code from the mounted directory to the local directory
mkdir -p $LOCAL_REPO_DIR
chmod 777 $LOCAL_REPO_DIR
cd $LOCAL_REPO_DIR
rsync -a --delete --exclude='env' --exclude='run_server.sh' --exclude='build_*' --exclude='build' --exclude='models*' --exclude='.vs*' --exclude='.git/objects*' /mnt/llama_cpp_mount/ ./
git config --global --add safe.directory $LOCAL_REPO_DIR
echo "compiling git revision: $(git rev-parse --short HEAD)"
mkdir -p ./build_qnn
rm -rf ./build_qnn/*
cd ./build_qnn
set -e

_extra_options="$CMAKE_EXTRA_BUILD_OPTIONS"
if [ "$TARGET_PLATFORM" = "android" ]; then
    if [ -z "$ANDROID_NDK_HOME" ]; then
        echo "ANDROID_NDK_HOME is not set"
        exit 1
    fi
    if [ -z "$ANDROID_PLATFORM" ]; then
        echo "ANDROID_PLATFORM is not set"
        exit 1
    fi

    _android_ndk_options="-DANDROID_ABI=$TARGET_ARCH \
        -DANDROID_PLATFORM=$ANDROID_PLATFORM \
        -DANDROID_NDK=$ANDROID_NDK_HOME \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
    _extra_options="$_extra_options $_android_ndk_options"
    _qnn_libs_path="$QNN_SDK_PATH/lib/aarch64-android"
elif [ "$TARGET_PLATFORM" = "linux" ]; then
    _extra_options="$_extra_options"
    if [ "$TARGET_ARCH" = "x86_64" ]; then
        _qnn_libs_path="$QNN_SDK_PATH/lib/x86_64-linux-clang"
    elif [ "$TARGET_ARCH" = "arm64-v8a" ]; then
        _qnn_libs_path="$QNN_SDK_PATH/lib/aarch64-oe-linux-gcc11.2"
    else
        echo "TARGET_ARCH is not x86_64 or arm64-v8a"
        exit 1
    fi
else
    echo "TARGET_PLATFORM is not android or linux"
    exit 1
fi

if [ $GGML_HEXAGON -eq 1 ]; then
    echo "Using official GGML hexagon support"
    # See also: https://github.com/CodeLinaro/llama.cpp/blob/hexagon/docs/backend/hexagon/README.md
    _extra_options="${_extra_options} -DGGML_QNN=off -DGGML_QNN_ENABLE_HEXAGON_BACKEND=off"
    _extra_options="${_extra_options} -DGGML_HEXAGON=on -DGGML_OPENMP=off -DHEXAGON_SDK_ROOT=${HEXAGON_SDK_PATH} -DPREBUILT_LIB_DIR=android_aarch64"
else
    echo "Using custom hexagon support"
    if [ $BUILD_HEXAGON_BACKEND -eq 1 ]; then
        _extra_options="${_extra_options} -DGGML_QNN_ENABLE_HEXAGON_BACKEND=on"
    fi

    if [ $BUILD_HEXAGON_NPU_ONLY -eq 1 ]; then
        echo "Building for Hexagon NPU only"
        _extra_options="${_extra_options} -DGGML_HEXAGON_NPU_ONLY=on"
    else
        _extra_options="${_extra_options} -DGGML_HEXAGON_NPU_ONLY=off"
    fi

    if [ $DISABLE_HEXAGON_AND_QNN -eq 1 ]; then
        echo "Building for cpu only"
        _extra_options="${_extra_options} -DGGML_QNN=off"
    else
        _extra_options="${_extra_options} -DGGML_QNN=on"
    fi
fi

# Build llama
cmake -H.. -B. $_extra_options \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE

cmake --build . --config $BUILD_TYPE -- -j$_cpu_count

# Copy the output files to the output directory
chmod -R u+rw $OUTPUT_DIR

rsync -av ./bin/llama-* $OUTPUT_DIR
rsync -av ./bin/test-backend-ops $OUTPUT_DIR
if [ -e ./bin/lldb-server ]; then
    rsync -av ./bin/lldb-server $OUTPUT_DIR
elif [ -e ./bin/gdbserver ]; then
    rsync -av ./bin/gdbserver $OUTPUT_DIR
fi

if [ -e ./bin/sysMonApp ]; then
    rsync -av ./bin/sysMonApp $OUTPUT_DIR
fi

if [ $DISABLE_HEXAGON_AND_QNN -eq 0 ]; then
    rsync -av ./bin/*.so $OUTPUT_DIR
fi

chown -R "$HOST_USER_ID" "$OUTPUT_DIR"

set +e
