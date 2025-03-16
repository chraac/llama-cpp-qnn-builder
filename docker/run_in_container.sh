#/bin/bash

echo "EXEC_MOUNT_POINT: $EXEC_MOUNT_POINT"
echo "RUN_LOG_PATH: $RUN_LOG_PATH"

cd $EXEC_MOUNT_POINT
set -e

./test-backend-ops test -b qnn-cpu >$RUN_LOG_PATH/test-backend-ops-all-cpu.log 2>&1
./test-backend-ops test -b qnn-npu >$RUN_LOG_PATH/test-backend-ops-all-npu.log 2>&1

set +e
