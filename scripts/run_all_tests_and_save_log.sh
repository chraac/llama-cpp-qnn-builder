#!/bin/bash

_SCRIPT_PATH=$(dirname "$(realpath "$0")")
_DEVICE_PATH='/data/local/tmp'
_LOG_FILE_PATH="$_SCRIPT_PATH/../run_logs/test-backend-ops_all.log"
_SHOULD_PUSH_TO_DEVICE=0

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -p | --push-to-device)
        _SHOULD_PUSH_TO_DEVICE=1
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

adb shell "cd $_DEVICE_PATH && LLAMA_CACHE=$_DEVICE_PATH/cache ./test-backend-ops test" >$_LOG_FILE_PATH 2>&1
