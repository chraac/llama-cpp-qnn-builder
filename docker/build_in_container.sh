#/bin/bash

echo "LOCAL_REPO_DIR: $LOCAL_REPO_DIR"
echo "QNN_SDK_PATH: $QNN_SDK_PATH"
echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
echo "TARGET_PLATFORM: $TARGET_PLATFORM"
echo "TARGET_ARCH: $TARGET_ARCH"
echo "ANDROID_API_LEVEL: $ANDROID_PLATFORM"
echo "BUILD_TYPE: $BUILD_TYPE"

mkdir -p $LOCAL_REPO_DIR
chmod 777 $LOCAL_REPO_DIR
cd $LOCAL_REPO_DIR
rsync -a --delete --exclude=env --exclude='run_server.sh' --exclude='build/*' --exclude='build_*' --exclude='models/*' /mnt/llama_cpp_mount/ ./
git config --global --add safe.directory $LOCAL_REPO_DIR
echo "compiling git revision: $(git rev-parse --short HEAD)"
mkdir -p ./build_qnn
rm -rf ./build_qnn/*
cd ./build_qnn
set -e

if [ -z "$QNN_SDK_PATH" ]; then
    echo "QNN_SDK_PATH is not set"
    exit 1
fi

if [ -z "$TARGET_ARCH" ]; then
    echo "TARGET_ARCH is not set"
    exit 1
fi

_extra_options="$CMAKE_EXTRA_OPTIONS"
if [ "$TARGET_PLATFORM" = "android" ]; then
    if [ -z "$ANDROID_NDK_HOME" ]; then
        echo "ANDROID_NDK_HOME is not set"
        exit 1
    fi
    if [ -z "$ANDROID_PLATFORM" ]; then
        echo "ANDROID_PLATFORM is not set"
        exit 1
    fi

    _android_ndk_options="-DANDROID_ABI=$TARGET_ARCH -DANDROID_PLATFORM=$ANDROID_PLATFORM -DANDROID_NDK=$ANDROID_NDK_HOME -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
    _extra_options="$_extra_options $_android_ndk_options"
    _qnn_libs_path="$QNN_SDK_PATH/lib/aarch64-android"
elif [ "$TARGET_PLATFORM" = "linux" ]; then
    _extra_options="$_extra_options $_android_ndk_options"
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

cmake -H.. -B. -DGGML_QNN=on $_extra_options -DGGML_QNN_SDK_PATH="$QNN_SDK_PATH" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
make -j $(nproc)
chmod -R u+rw $OUTPUT_DIR
rsync -av ./bin/llama-* $OUTPUT_DIR
rsync -av ./bin/test-backend-ops $OUTPUT_DIR
rsync -av $_qnn_libs_path/libQnnSystem.so $OUTPUT_DIR
rsync -av $_qnn_libs_path/libQnnCpu.so $OUTPUT_DIR
rsync -av $_qnn_libs_path/libQnnGpu.so $OUTPUT_DIR
rsync -av $_qnn_libs_path/libQnnHtp.so $OUTPUT_DIR
rsync -av $_qnn_libs_path/libQnnHtpNetRunExtensions.so $OUTPUT_DIR
rsync -av $_qnn_libs_path/libQnnHtpPrepare.so $OUTPUT_DIR
rsync -av $_qnn_libs_path/libQnnHtp*Stub.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/hexagon-*/unsigned/libQnnHtp*Skel.so $OUTPUT_DIR
rsync -av $ANDROID_NDK_HOME/prebuilt/android-arm64/gdbserver/gdbserver $OUTPUT_DIR
chown -R "$HOST_USER_ID" "$OUTPUT_DIR"
set +e
