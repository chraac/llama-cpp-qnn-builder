#!/bin/bash

_SCRIPT_PATH=$(dirname "$(realpath "$0")")
_DEVICE_PATH='/data/local/tmp'
_LOG_FILE_NAME='llama-bench-f32-qnn-gpu-debug.log'
_MODEL_NAME='meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf'
_SHOULD_PUSH_TO_DEVICE=0

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --log-file-name)
        _LOG_FILE_NAME="$2"
        shift
        shift
        ;;
    --push-to-device)
        _SHOULD_PUSH_TO_DEVICE=1
        shift
        ;;
    --model-name)
        _MODEL_NAME="$2"
        shift
        shift
        ;;
    *)
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

if [ $_SHOULD_PUSH_TO_DEVICE -eq 1 ]; then
    "$_SCRIPT_PATH/push_and_run_test.sh" -p
fi

LOG_FILE_PATH="$_SCRIPT_PATH/../$_LOG_FILE_NAME"
# adb shell 'cd /data/local/tmp/ && LLAMA_CACHE=/data/local/tmp/cache ./llama-bench --progress -v -mmp 0 -m meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf' > llama-bench-f32-qnn-gpu-debug.log 2>&1
COMMAND_STRING="cd $_DEVICE_PATH && "
COMMAND_STRING+="LLAMA_CACHE=$_DEVICE_PATH/cache "
COMMAND_STRING+="./llama-bench --progress -v -mmp 0 -p 512 -n 128 -m $_MODEL_NAME"
adb shell $COMMAND_STRING >$LOG_FILE_PATH 2>&1
