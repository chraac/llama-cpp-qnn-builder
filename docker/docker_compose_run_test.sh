_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
_run_logs_dir="$_script_dir/../run_logs"

set -e

mkdir -p "$_run_logs_dir"
rm -rf "$_run_logs_dir/test-backend-ops-all-npu.log"
pushd "$_script_dir"
_extra_args='--exit-code-from llama-qnn-run'
_compose_command='docker compose -f docker-compose-run.yml'
$_compose_command build --pull
$_compose_command up --build $_extra_args
popd

set +e
