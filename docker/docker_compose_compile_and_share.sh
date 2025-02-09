_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
_llama_cpp_repo_dir="$_script_dir/../llama.cpp"
_llama_cpp_output_dir="$_script_dir/../build_qnn"
_smb_share_dir="$HOME/smb_shared/qnn/"
_rebuild=0
_build_type='Release'
_copy_to_smb=0
_user_id=$(id -u)
_reset_submodules=0
_update_submodules=0
_in_ci=0
_pull_latest=0
_print_build_time=0

# Parse command-line arguments
while (("$#")); do
    case "$1" in
    -r | --rebuild)
        _rebuild=1
        shift
        ;;
    --repo-dir)
        _llama_cpp_repo_dir="$2"
        shift 2
        ;;
    -d | --debug)
        _build_type='Debug'
        shift
        ;;
    -s | --smb)
        _copy_to_smb=1
        shift
        ;;
    --reset-submodules)
        _reset_submodules=1
        shift
        ;;
    --update-submodules)
        _update_submodules=1
        shift
        ;;
    --ci)
        _in_ci=1
        shift
        ;;
    --pull)
        _pull_latest=1
        shift
        ;;
    --print-build-time)
        _print_build_time=1
        shift
        ;;
    *) # preserve positional arguments
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

set -e

pushd "$_llama_cpp_repo_dir"
if [ $_update_submodules -eq 1 ]; then
    git submodule foreach --recursive git reset --hard
    git submodule foreach --recursive git fetch
    git submodule update --remote --recursive
    git submodule update --init --recursive --checkout
    git submodule foreach --recursive git reset --hard
    _reset_submodules=0
fi

if [ $_reset_submodules -eq 1 ]; then
    git submodule foreach --recursive git reset --hard
    git submodule update --recursive
    git submodule update --init --recursive --checkout
fi

_repo_git_hash=$(git rev-parse --short HEAD)
popd

echo "------------------------------------------------------------"
echo "script_dir: $_script_dir"
echo "repo_dir: $_llama_cpp_repo_dir"
echo "repo_revision: $_repo_git_hash"
echo "output_dir: $_llama_cpp_output_dir"
echo "build_type: $_build_type"
echo "------------------------------------------------------------"

if [ $_print_build_time -eq 1 ]; then
    _start_time=$(date +%s)
fi

mkdir -p $_llama_cpp_output_dir
pushd "$_script_dir"

_extra_args='--exit-code-from llama-qnn-compile'
export LLAMA_CPP_REPO=$_llama_cpp_repo_dir
export OUTPUT_PATH=$_llama_cpp_output_dir
export BUILD_TYPE=$_build_type
export HOST_USER_ID=$_user_id
if [ $_pull_latest -eq 1 ]; then
    echo 'Pull latest image'
    docker compose -f docker-compose-compile.yml stop
    docker compose -f docker-compose-compile.yml down --rmi all
    docker compose -f docker-compose-compile.yml rm -f
    docker image prune
    docker compose -f docker-compose-compile.yml pull
fi
docker compose -f docker-compose-compile.yml build --pull
docker compose -f docker-compose-compile.yml up --build $_extra_args
if [ $_copy_to_smb -eq 1 ]; then
    rsync -avL --omit-dir-times --progress $_llama_cpp_output_dir $_smb_share_dir
fi

set +e

popd

if [ $_print_build_time -eq 1 ]; then
    _total_time=$(date +%s)
    _total_time=$((($_total_time - $_start_time)))
    # print total time in min and sec
    echo "Total build time: $(($_total_time / 60)) min $(($_total_time % 60)) sec"
fi
echo "All succeeded, revision: $_repo_git_hash"
