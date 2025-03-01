#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_device_path='/data/local/tmp'
_log_file_name='llama-bench-batch-qnn-gpu-debug.log'
_model_list=('meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf' 'meta-llama_Meta-Llama-3.2-3B-Instruct-Q4_K_M.gguf' 'meta-llama_Meta-Llama-3-8B-Instruct-Q4_K_M.gguf')
_should_push_to_device=0
_verbose_log=0

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --log-file-name)
        _log_file_name="$2"
        shift
        shift
        ;;
    --push-to-device)
        _should_push_to_device=1
        shift
        ;;
    --verbose)
        _verbose_log=1
        shift
        ;;
    *)
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

if [ $_should_push_to_device -eq 1 ]; then
    "$_script_path/push_and_run_test.sh" -p
fi

extra_args=""
if [ $_verbose_log -eq 1 ]; then
    extra_args="-v"
fi

log_file_path="$_script_path/../$_log_file_name"

function run_benchmark() {
    # adb shell 'cd /data/local/tmp/ && LLAMA_CACHE=/data/local/tmp/cache ./llama-bench --progress -v -mmp 0 -m meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf' > llama-bench-f32-qnn-gpu-debug.log 2>&1
    local model_name=$1
    local command_string="cd $_device_path && "
    command_string+="LLAMA_CACHE=$_device_path/cache "
    command_string+="./llama-bench --progress ${extra_args} -mmp 0 -p 512 -n 128 -m $model_name"
    adb shell $command_string
}

for model in "${_model_list[@]}"; do
    echo "Running benchmark for $model..." >>$log_file_path 2>&1
    run_benchmark $model >>$log_file_path 2>&1
done
