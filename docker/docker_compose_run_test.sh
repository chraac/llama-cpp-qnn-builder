_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
_run_logs_dir="$_script_dir/../run_logs"
_test_backend='all'

# Parse command-line arguments
while (("$#")); do
    case "$1" in
    -b | --backend)
        _test_backend="$2"
        shift 2
        ;;
    *) # preserve positional arguments
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

mkdir -p "$_run_logs_dir"
pushd "$_script_dir"

set -e

export TEST_BACKEND="$_test_backend"
_extra_args='--exit-code-from llama-qnn-run'
_compose_command='docker compose -f docker-compose-run.yml'
$_compose_command build --pull

set +e

$_compose_command up --build $_extra_args

# check return code
if [ $? -ne 0 ]; then
    echo -e "\e[31mTest failed!\e[0m"
    exit 1
fi

echo -e "\e[32mTest passed!\e[0m"

popd
