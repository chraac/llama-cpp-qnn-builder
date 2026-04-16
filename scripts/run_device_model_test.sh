#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_device_exec_path='/data/local/tmp'
_device_model_path='/sdcard'
_model_name='meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf'
_prompt='I believe the meaning of life is'
_prompt_long='You are an expert software engineer with deep knowledge of systems programming, machine learning, and distributed systems. Please analyze the following problem and provide a comprehensive solution. Question: I'm building a high-performance inference engine for large language models. The system needs to handle thousands of concurrent requests with low latency while maximizing GPU utilization. What architectural patterns should I consider? Context: Our current setup uses a simple request queue with a single model instance. Under high load, we see significant latency spikes and GPU memory fragmentation. The model is a 7B parameter transformer with 32 layers, 4096 hidden dimension, and 32 attention heads. We're using CUDA 12 with FlashAttention 2. Requirements: 1. P99 latency under 100ms for batch sizes up to 32 2. Support for both streaming and batch inference 3. Dynamic batching with timeout-based scheduling 4. Memory-efficient KV cache management 5. Graceful degradation under overload conditions Please provide: A detailed architecture design, key algorithms and data structures, memory optimization strategies, potential bottlenecks and mitigation approaches, and code examples for critical components.'
_should_push_to_device=0
_extra_prompt=0
_flash_attn=0
_max_tokens=512
_extra_args=""
_log_file_name="llama-completion-test-llama3-1b-q4k-hexagon-npu-release"
_log_file_ext=".log"
_log_file_path="$_script_path/../run_logs/${_log_file_name}$_log_file_ext"
_logcat_output_path="$_script_path/../run_logs/${_log_file_name}_logcat$_log_file_ext"

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -m | --model-name)
        _model_name="$2"
        shift
        shift
        ;;
    -v | --verbose)
        _extra_args="$_extra_args -v"
        shift
        ;;
    -p | --push-to-device)
        _should_push_to_device=1
        shift
        ;;
    -e | --extra-prompt)
        _extra_prompt=1
        shift
        ;;
    -f | --flash-attn)
        _flash_attn=1
        shift
        ;;
    -t | --max-tokens)
        _max_tokens="$2"
        shift
        shift
        ;;
    -l | --log-file-name)
        _log_file_name="$2"
        _log_file_path="$_script_path/../run_logs/${_log_file_name}$_log_file_ext"
        _logcat_output_path="$_script_path/../run_logs/${_log_file_name}_logcat$_log_file_ext"
        shift
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

if [ $_flash_attn -eq 1 ]; then
    _extra_args="${_extra_args} --flash-attn on"
fi

_extra_args="${_extra_args} -n $_max_tokens --ignore-eos"

echo "extra_args: $_extra_args"
echo "log_file_name: $_log_file_name"
echo "logcat_output_path: $_logcat_output_path"

_prompt_string=""
if [ $_extra_prompt -eq 1 ]; then
    _prompt_string="$_prompt_long"
else
    _prompt_string="$_prompt"
fi

device_command_string="cd $_device_exec_path && "
device_command_string+="GGML_HEXAGON_EXPERIMENTAL=1 LLAMA_CACHE=$_device_exec_path/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
device_command_string+="./llama-completion $extra_args -m '$_device_model_path/${_model_name}' --fit on -no-cnv -s 1234 -c 4096 -p '$_prompt_string'"

adb logcat -c
adb logcat -s 'adsprpc' 'llama-completion' 'pid-' >$_logcat_output_path 2>&1 &
logcat_pid=$!

adb shell $device_command_string >$_log_file_path 2>&1

sleep 5

kill $logcat_pid