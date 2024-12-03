#!/bin/bash

DEVICE_PATH='/data/local/tmp/'
PORT=23456
PARAMETERS='test'
SHOULD_FORWARD_PORT=false
EXECUTABLE_NAME='test-backend-ops'

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -p) SHOULD_FORWARD_PORT=true ;;
    -exec)
        EXECUTABLE_NAME="$2"
        shift
        ;;
    -params)
        PARAMETERS="$2"
        shift
        ;;
    esac
    shift
done

# Start the job
adb shell "cd $DEVICE_PATH && ./gdbserver :$PORT ./$EXECUTABLE_NAME $PARAMETERS" &

# Forward the port if needed
if [ "$SHOULD_FORWARD_PORT" = true ]; then
    adb forward tcp:$PORT tcp:$PORT
    adb forward --list
fi

# Wait for the job to finish
wait
