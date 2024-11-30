_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
_llama_cpp_repo_dir="$_script_dir/../llama.cpp"
_llama_cpp_output_dir="$_script_dir/../build"
_build_type='Release'
_rebuild=0

# Parse command-line arguments
while (("$#")); do
    case "$1" in
    -d | --debug)
        _build_type='Debug'
        shift
        ;;
    -r | --rebuild)
        _rebuild=1
        shift
        ;;
    --repo-dir)
        _llama_cpp_repo_dir="${2/#\~/$HOME}"
        _llama_cpp_output_dir="$_llama_cpp_repo_dir/build"
        shift 2
        ;;
    *) # preserve positional arguments
        echo "Invalid option $1"
        exit 1
        ;;
    esac
done

set -e
if [ $_rebuild -eq 1 ]; then
    rm -rf $_llama_cpp_output_dir
fi
mkdir -p $_llama_cpp_output_dir
pushd $_llama_cpp_output_dir
cmake ..
cmake --build . --config $_build_type
popd
set +e
