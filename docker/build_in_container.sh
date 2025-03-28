#/bin/bash

echo "LOCAL_REPO_DIR: $LOCAL_REPO_DIR"
echo "QNN_SDK_PATH: $QNN_SDK_PATH"
echo "HEXAGON_SDK_PATH: $HEXAGON_SDK_PATH"
echo "BUILD_HEXAGON_PACKAGE: $BUILD_HEXAGON_PACKAGE"
echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
echo "TARGET_PLATFORM: $TARGET_PLATFORM"
echo "TARGET_ARCH: $TARGET_ARCH"
echo "ANDROID_API_LEVEL: $ANDROID_PLATFORM"
echo "BUILD_TYPE: $BUILD_TYPE"
echo "CMAKE_EXTRA_BUILD_OPTIONS: $CMAKE_EXTRA_BUILD_OPTIONS"

if [ -z "$QNN_SDK_PATH" ]; then
    echo "QNN_SDK_PATH is not set"
    exit 1
fi

if [ -z "$TARGET_ARCH" ]; then
    echo "TARGET_ARCH is not set"
    exit 1
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

    if [ "$BUILD_TYPE" = "Release" ]; then
        # workaround for android ndk r23
        # for more detail: https://github.com/android/ndk/issues/1740
        BUILD_TYPE="MinSizeRel"
        echo "Building for android release $BUILD_TYPE"
    fi
    # disable openmp for android
    _android_ndk_options="-DANDROID_ABI=$TARGET_ARCH \
        -DGGML_OPENMP='off' \
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

# Build llama
cmake -H.. -B. \
    -DGGML_QNN=on $_extra_options \
    -DGGML_QNN_SDK_PATH="$QNN_SDK_PATH" \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE

cmake --build . --config $BUILD_TYPE -- -j$(nproc)

# Copy the output files to the output directory
chmod -R u+rw $OUTPUT_DIR
rsync -av ./bin/llama-* $OUTPUT_DIR
rsync -av ./bin/test-backend-ops $OUTPUT_DIR
rsync -av ./bin/*.so $OUTPUT_DIR
chown -R "$HOST_USER_ID" "$OUTPUT_DIR"

if [ $BUILD_HEXAGON_PACKAGE -eq 1 ]; then
    echo "Building hexagon package"
    source $QNN_SDK_PATH/bin/envsetup.sh
    # TODO: install python3 to fix the error here
    set +e
    source $HEXAGON_SDK_PATH/setup_sdk_env.source
    set -e
    cd ../ggml/src/ggml-qnn/hexagon/GgmlOpPackage
    cpu_count="$(nproc)"
    package_name='GgmlOpPackage'
    make all -j$cpu_count PACKAGE_NAME=$package_name
    make htp_v73 -j$cpu_count PACKAGE_NAME=$package_name
    make htp_v75 -j$cpu_count PACKAGE_NAME=$package_name
    make htp_v79 -j$cpu_count PACKAGE_NAME=$package_name
fi

set +e
