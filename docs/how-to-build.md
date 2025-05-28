# How to Build

This guide describes the steps to build a Android/Windows release of the QNN backend.

## Android

1. Install latest docker engine follow the official steps: [Install Docker Engine](https://docs.docker.com/engine/install/)
1. Clone my [llama-cpp-qnn-builder](https://github.com/chraac/llama-cpp-qnn-builder) repo (please update to latest `main` since we're using NDK r23, and there're some optimization flag not correctly applied in `Release` build, see: https://github.com/android/ndk/issues/1740)
1. In builder folder, run `docker\docker_compose_compile_and_share.sh` 
1. Console output will look like this one, and exectualbe is located at `build_qnn_arm64-v8a\bin\`
  ![image](https://github.com/user-attachments/assets/101a97be-efdf-455d-9d3c-a593311e144a)

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
