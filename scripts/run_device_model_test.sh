#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_device_exec_path='/data/local/tmp'
_device_model_path='/sdcard'
_model_name='meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf'
_prompt='I believe the meaning of life is'
_should_push_to_device=0
_flash_attn=0
_max_tokens=512
_extra_args="--ignore-eos --no-mmap -no-cnv -s 1234"
_log_file_name="llama-cli-test-llama3-1b-q4k-hexagon-npu-release"
_log_file_ext=".log"
_log_file_path="$_script_path/../run_logs/${_log_file_name}$_log_file_ext"
_logcat_output_path="$_script_path/../run_logs/${_log_file_name}.logcat$_log_file_ext"

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
        _logcat_output_path="$_script_path/../run_logs/${_log_file_name}.logcat$_log_file_ext"
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

_extra_args="${_extra_args} -n $_max_tokens"

echo "extra_args: $_extra_args"
echo "log_file_name: $_log_file_name"
echo "logcat_output_path: $_logcat_output_path"

device_command_string="cd $_device_exec_path && "
device_command_string+="LLAMA_CACHE=$_device_exec_path/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
device_command_string+="./llama-cli -m '$_device_model_path/${_model_name}' $_extra_args -p '$_prompt'"

adb logcat -c
adb logcat -s 'adsprpc' 'llama-cli' >$_logcat_output_path 2>&1 &
logcat_pid=$!

adb shell $device_command_string >$_log_file_path 2>&1

sleep 5

kill $logcat_pid