#/bin/bash

echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
echo "QNN_SDK_PATH: $QNN_SDK_PATH"
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
_android_ndk_options="-DANDROID_ABI=$TARGET_ARCH -DANDROID_PLATFORM=$ANDROID_PLATFORM -DANDROID_NDK=$ANDROID_NDK_HOME -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
cmake -H.. -B. -DGGML_QNN=on $CMAKE_EXTRA_OPTIONS $_android_ndk_options -DGGML_QNN_SDK_PATH="$QNN_SDK_PATH" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
make -j $(nproc)
chmod -R u+rw $OUTPUT_DIR
rsync -av ./bin/llama-* $OUTPUT_DIR
rsync -av ./bin/test-backend-ops $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/aarch64-android/libQnnSystem.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/aarch64-android/libQnnCpu.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/aarch64-android/libQnnGpu.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/aarch64-android/libQnnHtp.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/aarch64-android/libQnnHtpNetRunExtensions.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/aarch64-android/libQnnHtpPrepare.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/aarch64-android/libQnnHtp*Stub.so $OUTPUT_DIR
rsync -av $QNN_SDK_PATH/lib/hexagon-*/unsigned/libQnnHtp*Skel.so $OUTPUT_DIR
rsync -av $ANDROID_NDK_HOME/prebuilt/android-arm64/gdbserver/gdbserver $OUTPUT_DIR
chown -R "$HOST_USER_ID" "$OUTPUT_DIR"
set +e
