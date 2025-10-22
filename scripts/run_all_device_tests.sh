#!/bin/bash

_script_path=$(dirname "$(realpath "$0")")

push_to_device=0
benchmarks_only=0
test_only=0
revision=""
subdirectory=""

# Usage helper
usage() {
	cat <<EOF
Usage: $(basename "$0") [options]

Options:
	-p                 Push binaries/models to device before running
	-b                 Run benchmarks only (skip full test suite)
	-t                 Run tests only (skip perf/model/benchmarks block)
	-r <revision>      Revision or label to append to log file names
	-s <subdir>        Subdirectory under run_logs/ to place logs
	-h                 Show this help

Behavior mirrors scripts/run_all_device_tests.ps1 using .sh helpers.
EOF
}

while getopts ":pbtr:s:h" opt; do
    case $opt in
        p) push_to_device=1 ;;
        b) benchmarks_only=1 ;;
        t) test_only=1 ;;
        r) revision="$OPTARG" ;;
        s) subdirectory="$OPTARG" ;;
        h) usage; exit 0 ;;
        :) echo "Error: Option -$OPTARG requires an argument" >&2; usage; exit 1 ;;
        \?) echo "Error: Invalid option -$OPTARG" >&2; usage; exit 1 ;;
    esac
done

# If requested, push to device first
if [[ $push_to_device -eq 1 ]]; then
    "${_script_path}/push_and_run_test.sh" -p
fi

# Prepare log name helper that optionally prefixes a subdirectory
prefix_if_needed() {
    local name="$1"
    if [[ -n "$subdirectory" ]]; then
        echo "${subdirectory}/${name}"
    else
        echo "$name"
    fi
}

# Ensure subdirectory exists (proactive): run_logs/<subdir>
if [[ -n "$subdirectory" ]]; then
    mkdir -p "${_script_path}/../run_logs/${subdirectory}"
fi

if [[ $test_only -eq 0 ]]; then
    # Compose log file names (may have a trailing dot if revision is empty, matching ps1 behavior)
    perf_log_name="test-backend-ops-perf-all.release.hexagon.${revision}"
    model_test_log_name="llama-cli-test-llama3-1b-q4-hexagon-npu-fa-512-release.${revision}"
    benchmark_log_name="llama-bench-batch-llama3-q4-hexagon-npu-release-no8bit.${revision}"
    
    perf_log_name=$(prefix_if_needed "$perf_log_name")
    model_test_log_name=$(prefix_if_needed "$model_test_log_name")
    benchmark_log_name=$(prefix_if_needed "$benchmark_log_name")
    
    echo "Running device performance tests and saving log to ${perf_log_name}"
    "${_script_path}/run_all_tests_and_save_log.sh" \
    -e "perf -b hexagon-npu" \
    -l "${perf_log_name}"
    
    echo "Running device model test and saving log to ${model_test_log_name}"
    "${_script_path}/run_device_model_test.sh" \
    -f \
    -m "meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_0.gguf" \
    -l "${model_test_log_name}" \
    -t 512
    
    echo "Running device benchmarks and saving log to ${benchmark_log_name}"
    "${_script_path}/batch_run_benchmarks_and_save_log.sh" \
    -l "${benchmark_log_name}" \
    -s \
    -f
fi

if [[ $benchmarks_only -eq 0 ]]; then
    test_log_name="test-backend-ops-all-release.hexagon.${revision}"
    test_log_name=$(prefix_if_needed "$test_log_name")
    
    echo "Running device tests and saving log to ${test_log_name}"
    "${_script_path}/run_all_tests_and_save_log.sh" \
    -e "test -b hexagon-npu" \
    -l "${test_log_name}"
fi

echo "All requested device test tasks completed."

