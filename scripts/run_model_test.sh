#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")
_ld_library_path="${_script_path}/../build_qnn_x86_64:$LD_LIBRARY_PATH"
_llama_cli="${_script_path}/../build_qnn_x86_64/llama-cli"
_model_full_path="${_script_path}/../run_logs/meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf"
_prompt="I believe the meaning of life is"
_log_file_path="${_script_path}/../run_logs/emulator/model_test.log"
_extra_args=''

# Parse command-line arguments
while (("$#")); do
    case "$1" in
    -v | --verbose)
        _extra_args="-v"
        shift
        ;;
    *) # preserve positional arguments
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

LD_LIBRARY_PATH=${_ld_library_path} $_llama_cli -no-cnv --model $_model_full_path -s 1234 $_extra_args -p "$_prompt" >$_log_file_path 2>&1
