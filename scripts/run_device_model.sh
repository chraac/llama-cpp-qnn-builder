#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_device_exec_path='/data/local/tmp'
_device_model_path='/data/local/tmp'
_model_name='meta-llama_Meta-Llama-3.2-1B-f32.gguf'

device_command_string="cd $_device_exec_path && "
device_command_string+="LLAMA_CACHE=$_device_exec_path/cache "
device_command_string+="./llama-cli -m $_device_model_path/${_model_name} --color -i -r \"User:\""

adb shell $device_command_string
