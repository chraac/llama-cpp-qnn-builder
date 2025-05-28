# How to Build

This guide describes the steps to build a Android/Windows release of the QNN backend.

## Android

1. Install latest docker engine follow the official steps: [Install Docker Engine](https://docs.docker.com/engine/install/)
1. Clone my [llama-cpp-qnn-builder](https://github.com/chraac/llama-cpp-qnn-builder) repo (please update to latest `main` since we're using NDK r23, and there're some optimization flag not correctly applied in `Release` build, see: https://github.com/android/ndk/issues/1740)
1. In builder folder, run `docker\docker_compose_compile_and_share.sh`
1. Console output will look like this one, and exectualbe is located at `build_qnn_arm64-v8a\bin\`
  ![image](https://github.com/user-attachments/assets/101a97be-efdf-455d-9d3c-a593311e144a)

### Build Script Parameters

| Parameter                   | Short | Description                                | Default             |
| --------------------------- | ----- | ------------------------------------------ | ------------------- |
| `--rebuild`                 | `-r`  | Force rebuild of the project               | `false`             |
| `--repo-dir`                |       | Specify llama.cpp repository directory     | `../llama.cpp`      |
| `--debug`                   | `-d`  | Build in Debug mode                        | `Release`           |
| `--print-build-time`        |       | Display build and test execution times     | `false`             |
| `--asan`                    |       | Enable AddressSanitizer                    | `false`             |
| `--build-linux-x64`         |       | Build for Linux x86_64 platform            | `android arm64-v8a` |
| `--perf-log`                |       | Enable Hexagon performance tracking        | `false`             |
| `--enable-hexagon-backend`  |       | Enable Hexagon backend support             | `false`             |
| `--hexagon-npu-only`        |       | Build Hexagon NPU backend only             | `false`             |
| `--disable-hexagon-and-qnn` |       | Disable both Hexagon and QNN backends      | `false`             |
| `--qnn-only`                |       | Build QNN backend only                     | `false`             |
| `--enable-dequant`          |       | Enable quantized tensor support in Hexagon | `false`             |

### Examples

```bash
# Basic build
./docker_compose_compile_and_share.sh

# Debug build with hexagon-npu backend
./docker_compose_compile_and_share.sh -d --enable-hexagon-backend

# Debug build with hexagon-npu backend only
./docker_compose_compile_and_share.sh -d --hexagon-npu-only

# Debug build with hexagon-npu backend only and npu quantized tensor support
./docker_compose_compile_and_share.sh -d --hexagon-npu-only --enable-dequant

# QNN-only build with performance logging
./docker_compose_compile_and_share.sh --qnn-only --perf-log

```

## Windows

### Build with Visual Studio 2022

1. Download Qualcomm AI Engine Direct SDK, from [here](https://www.qualcomm.com/developer/software/qualcomm-ai-engine-direct-sdk), and then extract it into a folder

1. Install the latest Visual Studio, make sure `clang` toolchain and 'cmake' are installed
![Image](https://github.com/user-attachments/assets/30ee11f7-9069-4793-856d-c64bcd5d563b)
![Image](https://github.com/user-attachments/assets/9a36dde5-0e41-4421-9161-e9b09cd32eb1)

1. Launch vs2022, tap `Continue without code`, and then in `File` menu, select `Open` -> `CMake`, in file open dialog, navigate to llama.cpp root directory, select `CMakeLists.txt`

1. Edit `llama.cpp\CMakePresets.json`, add following line to config `arm64-windows-llvm`
    ```diff
    {
        "name": "arm64-windows-llvm", "hidden": true,
        "architecture": { "value": "arm64",    "strategy": "external" },
        "toolset":      { "value": "host=x64", "strategy": "external" },
        "cacheVariables": {
    -        "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/cmake/arm64-windows-llvm.cmake"
    +        "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/cmake/arm64-windows-llvm.cmake",
    +        "GGML_QNN": "ON",
    +        "GGML_QNN_SDK_PATH": "<path to your Qualcomm AI Engine Direct SDK, like x:/ml/qnn_sdk/qairt/2.31.0.250130/>",
    +        "BUILD_SHARED_LIBS": "OFF"
        }
    },
    ```

1. Select config `arm64-windows-llvm-debug`
![Image](https://github.com/user-attachments/assets/be4afbc8-78be-457d-9498-53fb7ec43578)

1. In `Build` menu, tap `Build All`, output file are located at `build-arm64-windows-llvm-debug\bin\`
