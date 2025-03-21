#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_ld_library_path="${_script_path}/../build_qnn_x86_64:$LD_LIBRARY_PATH"
_llama_cli="${_script_path}/../build_qnn_x86_64/llama-cli"
_model_name='meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf'
_model_path="${_script_path}/../models"
_prompt="I believe the meaning of life is"
_log_file_path="${_script_path}/../run_logs/emulator/model_test.log"
_extra_args='--device none -n 64 --ignore-eos'

# Parse command-line arguments
while (("$#")); do
    case "$1" in
    -v | --verbose)
        _extra_args="${_extra_args} -v"
        shift
        ;;
    -m | --model-name)
        _model_name="$2"
        shift 2
        ;;
    *) # preserve positional arguments
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

LD_LIBRARY_PATH=${_ld_library_path} $_llama_cli -no-cnv --model "${_model_path}/${_model_name}" -s 1234 $_extra_args -p "$_prompt" >$_log_file_path 2>&1

# check return code
if [ $? -ne 0 ]; then
    echo -e "\e[31mTest failed!\e[0m"
    exit 1
fi

echo -e "\e[32mTest passed!\e[0m"
