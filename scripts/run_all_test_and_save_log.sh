#!/bin/bash

SCRIPT_PATH=$(dirname "$(realpath "$0")")
DEVICE_PATH='/data/local/tmp'
LOG_FILE_PATH="$SCRIPT_PATH/../test-backend-ops_all.log"

adb shell "cd $DEVICE_PATH && LLAMA_CACHE=$DEVICE_PATH/cache ./test-backend-ops test" >$LOG_FILE_PATH 2>&1
