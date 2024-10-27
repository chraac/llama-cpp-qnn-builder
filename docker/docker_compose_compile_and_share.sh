

_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
_llama_cpp_repo_dir="$_script_dir/../llama.cpp"
_llama_cpp_output_dir="$_script_dir/../build_qnn"
_smb_share_dir="$HOME/smb_shared/qnn/"
_rebuild=0
_build_type='Release'
_user_id=$(id -u)

# Parse command-line arguments
while (( "$#" )); do
    case "$1" in
        -r|--rebuild)
            _rebuild=1
            shift
            ;;
        --repo-dir)
            _llama_cpp_repo_dir="$2"
            shift 2
            ;;
        -d|--debug)
            _build_type='Debug'
            shift
            ;;
        *) # preserve positional arguments
            echo "Invalid option $1"
            exit 1
            ;;
    esac
done

mkdir -p $_llama_cpp_output_dir
echo "script_dir: $_script_dir"
pushd "$_script_dir"

set -e

LLAMA_CPP_REPO=$_llama_cpp_repo_dir OUTPUT_PATH=$_llama_cpp_output_dir BUILD_TYPE=$_build_type HOST_USER_ID=$_user_id docker compose -f docker-compose-compile.yml up --build
rsync -avL --omit-dir-times --progress $_llama_cpp_repo_dir/build_qnn/ $_smb_share_dir

set +e

popd