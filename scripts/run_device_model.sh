#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_device_exec_path='/data/local/tmp'
_device_model_path='/data/local/tmp'
_model_name='meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf'
_should_push_to_device=0
_extra_args=''

# parse arguments to get the log file name
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --model-name)
        _model_name="$2"
        shift
        shift
        ;;
    --verbose)
        _extra_args="-v"
        shift
        ;;
    -p | --push-to-device)
        _should_push_to_device=1
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

device_command_string="cd $_device_exec_path && "
device_command_string+="LLAMA_CACHE=$_device_exec_path/cache "
device_command_string+="./llama-cli $_extra_args -m \"$_device_model_path/${_model_name}\" --color -i -r \"User:\""

adb shell $device_command_string
