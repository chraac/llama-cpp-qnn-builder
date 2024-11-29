#!/bin/bash

IS_PUSH_ONLY=false
DEVICE_PATH='/data/local/tmp'
SCRIPT_PATH=$(dirname "$(realpath "$0")")
BUILD_PATH="$SCRIPT_PATH/../build_qnn"

if [ "$#" -eq 1 ]; then
    if [ "$1" == "-p" ]; then
        IS_PUSH_ONLY=true
    fi
fi

for file in "$BUILD_PATH"/*.so; do
    adb push "$file" "$DEVICE_PATH/"
done

push_executable() {
    local exec_name=$1
    local exec_full_path="$DEVICE_PATH/$exec_name"
    adb push "$BUILD_PATH/$exec_name" "$DEVICE_PATH/"
    adb shell "chmod +x $exec_full_path"
}

push_executable 'test-backend-ops'
push_executable 'llama-cli'
push_executable 'llama-bench'

push_debug_server() {
    local server_name=$1
    if [ -f "$BUILD_PATH/$server_name" ]; then
        adb push "$BUILD_PATH/$server_name" "$DEVICE_PATH/"
        adb shell "chmod +x $DEVICE_PATH/$server_name"
    else
        echo -e "\e[31m$server_name not found in $BUILD_PATH\e[0m"
    fi
}

push_debug_server 'lldb-server'
push_debug_server 'gdbserver'

if [ "$IS_PUSH_ONLY" = false ]; then
    echo -e "\e[32mRunning tests GGML_OP_ADD ...\e[0m"
    adb shell "$DEVICE_PATH/test-backend-ops -o ADD"
    
    echo -e "\e[32mRunning tests GGML_OP_MUL_MAT ...\e[0m"
    adb shell "$DEVICE_PATH/test-backend-ops -o MUL_MAT"
fi
