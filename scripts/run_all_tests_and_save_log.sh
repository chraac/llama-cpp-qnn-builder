#!/bin/bash

_SCRIPT_PATH=$(dirname "$(realpath "$0")")
_DEVICE_PATH='/data/local/tmp'
_LOG_FILE_NAME="test-backend-ops_all"
_LOG_FILE_EXTENSION=".log"
_LOG_FILE_PATH="$_SCRIPT_PATH/../run_logs/${_LOG_FILE_NAME}$_LOG_FILE_EXTENSION"
_LOGCAT_OUTPUT_PATH="$_SCRIPT_PATH/../run_logs/${_LOG_FILE_NAME}.logcat$_LOG_FILE_EXTENSION"
_SHOULD_PUSH_TO_DEVICE=0
_EXTRA_RUN_VARS="LLAMA_CACHE=./cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./"
_EXTRA_RUN_ARGS="test"

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -p | --push-to-device)
        _SHOULD_PUSH_TO_DEVICE=1
        shift
        ;;
    -e | --extra-args)
        _EXTRA_RUN_ARGS="$2"
        shift
        shift
        ;;
    -l | --log-file-name)
        _LOG_FILE_NAME="$2"
        _LOG_FILE_PATH="$_SCRIPT_PATH/../run_logs/${_LOG_FILE_NAME}$_LOG_FILE_EXTENSION"
        _LOGCAT_OUTPUT_PATH="$_SCRIPT_PATH/../run_logs/${_LOG_FILE_NAME}_logcat$_LOG_FILE_EXTENSION"
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

echo "ExtraArgs: $_EXTRA_RUN_ARGS"
echo "LogFilePath: $_LOG_FILE_PATH"

adb logcat -c
adb logcat -s 'adsprpc' 'test-backend-ops' >$_LOGCAT_OUTPUT_PATH 2>&1 &
LOGCAT_PID=$!

adb shell "cd $_DEVICE_PATH && $_EXTRA_RUN_VARS ./test-backend-ops $_EXTRA_RUN_ARGS" >$_LOG_FILE_PATH 2>&1

sleep 10

kill $LOGCAT_PID
