#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_ld_library_path="${_script_path}/../build_qnn_x86_64:$LD_LIBRARY_PATH"
_llama_cli="${_script_path}/../build_qnn_x86_64/llama-cli"
_model_name='meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf'
_model_path="${_script_path}/../models"
_verbose_log=0
_extra_args=''

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
        _verbose_log=1
        shift
        ;;
    *)
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

if [ $_verbose_log -eq 1 ]; then
    _extra_args="${_extra_args} -v"
else
    _extra_args="${_extra_args} --verbosity 0"
fi

LD_LIBRARY_PATH=${_ld_library_path} $_llama_cli $_extra_args -m "$_model_path/$_model_name" --no-mmap --color -i -r "User:"
