# Run a command repeatedly for a specified duration
# Usage: run_for [OPTIONS] COMMAND
# Options:
#   -t TIME     Run for TIME seconds (default: 60)
#   -i INTERVAL Sleep INTERVAL seconds between runs (default: 2)
#   -q          Quiet mode (suppress progress output)
run_for() {
    local duration=60
    local interval=2
    local quiet=0

    # Parse options
    while getopts "t:i:q" opt; do
        case $opt in
        t) duration=$OPTARG ;;
        i) interval=$OPTARG ;;
        q) quiet=1 ;;
        *)
            echo "Usage: run_for [-t seconds] [-i interval] [-q] command"
            return 1
            ;;
        esac
    done

    shift $((OPTIND - 1))
    local command="$@"

    if [ -z "$command" ]; then
        echo "Error: No command specified"
        echo "Usage: run_for [-t seconds] [-i interval] [-q] command"
        return 1
    fi

    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local current_time=$start_time
    local run_count=0

    echo "Running '$command' for $duration seconds (interval: ${interval}s)..."

    while [ $current_time -lt $end_time ]; do
        run_count=$((run_count + 1))

        if [ $quiet -eq 0 ]; then
            echo "[$run_count] $(date '+%H:%M:%S') - Running command..."
        fi

        eval "$command"

        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        remaining=$((end_time - current_time))

        if [ $remaining -le 0 ]; then
            break
        fi

        if [ $quiet -eq 0 ]; then
            echo "Elapsed: ${elapsed}s, Remaining: ${remaining}s"
        fi

        # Sleep for the interval or for the remaining time, whichever is smaller
        sleep_time=$interval
        if [ $remaining -lt $interval ]; then
            sleep_time=$remaining
        fi

        sleep $sleep_time
        current_time=$(date +%s)
    done

    total_time=$((current_time - start_time))
    echo "Finished after ${total_time}s with $run_count executions"
}

# Repeatedly run a command until Ctrl+C is pressed, then show total runtime
# Usage: repeat_cmd COMMAND [ARGS...]
repeat_cmd() {
    if [ -z "$1" ]; then
        echo "Error: No command specified"
        echo "Usage: repeat_cmd COMMAND [ARGS...]"
        return 1
    fi

    local start_time=$(date +%s)
    local count=0

    trap 'elapsed=$(($(date +%s) - start_time)); echo; echo "Total runtime: ${elapsed}s (${count} executions)"; return 0' INT

    while true; do
        count=$((count + 1))
        echo "[$(date '+%H:%M:%S')] Run #${count}"

        local cmd_start=$(date +%s)
        eval "$@"
        local cmd_end=$(date +%s)

        echo "Command took $((cmd_end - cmd_start)) seconds"
        echo
        sleep 1
    done
}

_script_dir="$(dirname "$(realpath "$0")")"
_working_dir="$(pwd)"
repeat_cmd "clear && $_script_dir/../docker/docker_compose_compile.sh --repo-dir '${_working_dir}' -r --hexagon-npu-only -d"
