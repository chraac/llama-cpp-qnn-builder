#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_device_path='/data/local/tmp'
_device_model_path='/sdcard'
_log_file_name='llama-bench-batch-qnn-gpu-debug.log'
_model_list=('meta-llama_Meta-Llama-3.2-1B-Instruct' 'meta-llama_Meta-Llama-3.2-3B-Instruct' 'meta-llama_Meta-Llama-3-8B-Instruct')
_should_push_to_device=0
_verbose_log=0
_skip_8b_model=0

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -l | --log-file-name)
        _log_file_name="$2"
        shift
        shift
        ;;
    -p | --push-to-device)
        _should_push_to_device=1
        shift
        ;;
    -v | --verbose)
        _verbose_log=1
        shift
        ;;
    -s | --skip-8b)
        _skip_8b_model=1
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

if [ $_skip_8b_model -eq 1 ]; then
    _model_list=('meta-llama_Meta-Llama-3.2-1B-Instruct' 'meta-llama_Meta-Llama-3.2-3B-Instruct')
fi

extra_args=""
if [ $_verbose_log -eq 1 ]; then
    extra_args="-v"
fi

log_file_path="$_script_path/../run_logs/$_log_file_name"

function run_benchmark() {
    # adb shell 'cd /data/local/tmp/ && LLAMA_CACHE=/data/local/tmp/cache ./llama-bench --progress -v -mmp 0 -m meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf' > llama-bench-f32-qnn-gpu-debug.log 2>&1
    local model_name=$1
    local command_string="cd $_device_path && "
    command_string+="LLAMA_CACHE=$_device_path/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
    command_string+="./llama-bench --progress ${extra_args} -mmp 0 -p 512 -n 128 -m ${_device_model_path}/$model_name"
    adb shell $command_string
}

for model in "${_model_list[@]}"; do
    _model_q4_0="${model}-Q4_0.gguf"
    echo "Running benchmark for $_model_q4_0..." >>$log_file_path 2>&1
    run_benchmark $_model_q4_0 >>$log_file_path 2>&1

    _model_q4_k_m="${model}-Q4_K_M.gguf"
    echo "Running benchmark for $_model_q4_k_m..." >>$log_file_path 2>&1
    run_benchmark $_model_q4_k_m >>$log_file_path 2>&1
done
