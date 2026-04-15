#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_device_exec_path='/data/local/tmp'
_device_model_path='/sdcard'
_model_name='meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf'
_prompt='I believe the meaning of life is'
_prompt_long='From an unlimited supply of 1-cent coins, 10-cent coins, and 25-cent coins, Silas wants to find a collection of coins that has a total value of $ N $ cents, where $ N $ is a positive integer. He uses the so-called **greedy algorithm**, successively choosing the coin of greatest value that does not cause the value of his collection to exceed $ N $. For example, to get 42 cents, Silas will choose a 25-cent coin, then a 10-cent coin, then 7 1-cent coins. However, this collection of 9 coins uses more coins than necessary to get a total of 42 cents; indeed, choosing 4 10-cent coins and 2 1-cent coins achieves the same total value with only 6 coins.
In general, the greedy algorithm succeeds for a given $ N $ if no other collection of 1-cent, 10-cent, and 25-cent coins gives a total value of $ N $ cents using strictly fewer coins than the collection given by the greedy algorithm. Find the number of values of $ N $ between 1 and 1000 inclusive for which the greedy algorithm succeeds.
Please reason step by step, and put your final answer within \boxed{}.'
_should_push_to_device=0
_extra_prompt=0
_flash_attn=0
_max_tokens=512
_extra_args="-n $_max_tokens --ignore-eos"
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