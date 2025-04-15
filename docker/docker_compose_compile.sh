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
_build_platform='android' # default build platform, could be 'android' or 'linux'
_build_arch='arm64-v8a'   # default build arch, could be 'arm64-v8a' or 'x86_64'
_build_options='-DBUILD_SHARED_LIBS=off -DGGML_QNN_ENABLE_CPU_BACKEND=on -DGGML_OPENMP=on -DLLAMA_CURL=OFF'
_extra_build_options=''
_run_backend_tests=0
_enable_hexagon_package=0

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
    --asan)
        _extra_build_options="${_extra_build_options} -DLLAMA_SANITIZE_ADDRESS=on"
        shift
        ;;
    --build-linux-x64)
        _build_platform='linux'
        _build_arch='x86_64'
        # disable the qnn cpu backend, let the test use ggml cpu backend to cross verify the results
        _extra_build_options="${_extra_build_options} -DLLAMA_SANITIZE_ADDRESS=on"
        shift
        ;;
    --perf-log)
        _extra_build_options="${_extra_build_options} -DGGML_QNN_ENABLE_PERFORMANCE_TRACKING=on"
        shift
        ;;
    --enable-hexagon-package)
        _enable_hexagon_package=1
        shift
        ;;
    --run-tests)
        _run_backend_tests=1
        shift
        ;;
    *) # preserve positional arguments
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

if [ $_enable_hexagon_package -eq 1 ]; then
    export BUILD_HEXAGON_PACKAGE=1
    _extra_build_options="${_extra_build_options} -DGGML_QNN_ENABLE_HEXAGON_PACKAGE=on"
else
    export BUILD_HEXAGON_PACKAGE=0
fi

_build_options="${_build_options} ${_extra_build_options}"

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

_llama_cpp_output_dir="$_script_dir/../build_qnn_${_build_arch}"

echo "------------------------------------------------------------"
echo "script_dir: $_script_dir"
echo "repo_dir: $_llama_cpp_repo_dir"
echo "repo_revision: $_repo_git_hash"
echo "output_dir: $_llama_cpp_output_dir"
echo "build_platform: $_build_platform"
echo "build_arch: $_build_arch"
echo "build_type: $_build_type"
echo "------------------------------------------------------------"

if [ $_print_build_time -eq 1 ]; then
    _start_time=$(date +%s)
fi

mkdir -p $_llama_cpp_output_dir
pushd "$_script_dir"

export LLAMA_CPP_REPO=$_llama_cpp_repo_dir
export OUTPUT_PATH=$_llama_cpp_output_dir
export BUILD_TYPE=$_build_type
export HOST_USER_ID=$_user_id
export TARGET_PLATFORM=$_build_platform
export TARGET_ARCH=$_build_arch
export CMAKE_EXTRA_BUILD_OPTIONS=$_build_options

_extra_args='--exit-code-from llama-qnn-compile'
_compose_command='docker compose -f docker-compose-compile.yml'
if [ $_pull_latest -eq 1 ]; then
    echo 'Pull latest image'
    $_compose_command stop
    $_compose_command down --rmi all
    $_compose_command rm -f
    $_compose_command pull
fi

$_compose_command build --pull
$_compose_command up --build $_extra_args
_build_end=$(date +%s)

if [ $_copy_to_smb -eq 1 ]; then
    rsync -avL --omit-dir-times --progress $_llama_cpp_output_dir $_smb_share_dir
fi

if [ $_run_backend_tests -eq 1 ]; then
    LD_LIBRARY_PATH="$_script_dir/../build_qnn_x86_64:$LD_LIBRARY_PATH" "$_script_dir/../build_qnn_x86_64/test-backend-ops" test -b qnn-cpu
    LD_LIBRARY_PATH="$_script_dir/../build_qnn_x86_64:$LD_LIBRARY_PATH" "$_script_dir/../build_qnn_x86_64/test-backend-ops" test -b qnn-npu
fi

_run_test_end=$(date +%s)

set +e

popd

if [ $_print_build_time -eq 1 ]; then
    _total_build_time=$((($_build_end - $_start_time)))
    _total_test_time=$((($_run_test_end - $_build_end)))
    # print total time in min and sec
    echo "Total build time: $(($_total_build_time / 60)) min $(($_total_build_time % 60)) sec"
    echo "Total test time: $(($_total_test_time / 60)) min $(($_total_test_time % 60)) sec"
fi
echo "All succeeded, revision: $_repo_git_hash"
