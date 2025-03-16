#/bin/bash

echo "EXEC_MOUNT_POINT: $EXEC_MOUNT_POINT"
echo "RUN_LOG_PATH: $RUN_LOG_PATH"
echo "TEST_BACKEND: $TEST_BACKEND"

cd $EXEC_MOUNT_POINT
set -e

if [ "$TEST_BACKEND" = "cpu" ] || [ "$TEST_BACKEND" = "all" ]; then
    ./test-backend-ops test -b qnn-cpu >$RUN_LOG_PATH/test-backend-ops-all-cpu.log 2>&1
fi

if [ "$TEST_BACKEND" = "npu" ] || [ "$TEST_BACKEND" = "all" ]; then
    ./test-backend-ops test -b qnn-npu >$RUN_LOG_PATH/test-backend-ops-all-npu.log 2>&1
fi

set +e
