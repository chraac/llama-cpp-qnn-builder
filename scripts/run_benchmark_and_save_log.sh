#!/bin/bash

SCRIPT_PATH=$(dirname "$(realpath "$0")")
DEVICE_PATH='/data/local/tmp'
LOG_FILE_NAME='llama-bench-f32-qnn-gpu-debug.log'
MODEL_NAME='meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf'

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --log-file-name)
        LOG_FILE_NAME="$2"
        shift
        shift
        ;;
    *)
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

LOG_FILE_PATH="$SCRIPT_PATH/../$LOG_FILE_NAME"
# adb shell 'cd /data/local/tmp/ && LLAMA_CACHE=/data/local/tmp/cache ./llama-bench --progress -v -mmp 0 -m meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf' > llama-bench-f32-qnn-gpu-debug.log 2>&1
COMMAND_STRING="cd $DEVICE_PATH && "
COMMAND_STRING+="LLAMA_CACHE=$DEVICE_PATH/cache "
COMMAND_STRING+="./llama-bench --progress -v -mmp 0 -m $MODEL_NAME"
adb shell $COMMAND_STRING >$LOG_FILE_PATH 2>&1
