_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

set -e

pushd "$_script_dir"
_extra_args='--exit-code-from llama-qnn-run'
_compose_command='docker compose -f docker-compose-run.yml'
$_compose_command build --pull
$_compose_command up --build $_extra_args
popd

set +e
