# How to Build

This guide describes the steps to build Android/Windows releases of the QNN backend for llama.cpp.

## Android

### Prerequisites

1. Install the latest Docker Engine following the official steps: [Install Docker Engine](https://docs.docker.com/engine/install/)
2. Clone the [llama-cpp-qnn-builder](https://github.com/chraac/llama-cpp-qnn-builder) repository
   ```bash
   git clone https://github.com/chraac/llama-cpp-qnn-builder.git
   cd llama-cpp-qnn-builder
   ```

> **Note**: Please update to the latest `main` branch as we're using NDK r23. There are optimization flags that weren't correctly applied in `Release` builds in earlier versions. See: https://github.com/android/ndk/issues/1740

### Building

1. Navigate to the project root directory and run the build script:
   ```bash
   ./docker/docker_compose_compile_and_share.sh
   ```

2. The console output will look similar to this, and executables will be located in `build_qnn_arm64-v8a/bin/`:
   ![Build Output](https://github.com/user-attachments/assets/101a97be-efdf-455d-9d3c-a593311e144a)

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

### Build Examples

```bash
# Basic build (default: Release mode, QNN + Hexagon backends)
./docker/docker_compose_compile_and_share.sh

# Debug build with Hexagon NPU backend
./docker/docker_compose_compile_and_share.sh -d --enable-hexagon-backend

# Debug build with Hexagon NPU backend only
./docker/docker_compose_compile_and_share.sh -d --hexagon-npu-only

# Debug build with Hexagon NPU backend and quantized tensor support
./docker/docker_compose_compile_and_share.sh -d --hexagon-npu-only --enable-dequant

# QNN-only build with performance logging
./docker/docker_compose_compile_and_share.sh --qnn-only --perf-log

# Force rebuild with debug symbols and build timing
./docker/docker_compose_compile_and_share.sh -r -d --print-build-time
```

## Windows

### Prerequisites

1. **Download Qualcomm AI Engine Direct SDK**
   - Get it from [Qualcomm Developer Portal](https://www.qualcomm.com/developer/software/qualcomm-ai-engine-direct-sdk)
   - Extract to a folder (e.g., `C:/ml/qnn_sdk/qairt/2.31.0.250130/`)

2. **Install Visual Studio 2022**
   - Ensure the following components are installed:
     - **Clang toolchain** for ARM64 compilation
        ![VS2022 Clang Installation](https://github.com/user-attachments/assets/30ee11f7-9069-4793-856d-c64bcd5d563b)
     - **CMake tools** for Visual Studio
        ![VS2022 CMake Installation](https://github.com/user-attachments/assets/9a36dde5-0e41-4421-9161-e9b09cd32eb1)

### Build Steps

1. **Open the Project**
   - Launch Visual Studio 2022
   - Click `Continue without code`
   - Go to `File` → `Open` → `CMake`
   - Navigate to the `llama.cpp` root directory and select `CMakeLists.txt`

2. **Configure CMake Presets**
   
   Edit `llama.cpp/CMakePresets.json` and modify the `arm64-windows-llvm` configuration:

   ```diff
   {
       "name": "arm64-windows-llvm", 
       "hidden": true,
       "architecture": { "value": "arm64", "strategy": "external" },
       "toolset": { "value": "host=x64", "strategy": "external" },
       "cacheVariables": {
   -        "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/cmake/arm64-windows-llvm.cmake"
   +        "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/cmake/arm64-windows-llvm.cmake",
   +        "GGML_QNN": "ON",
   +        "GGML_QNN_SDK_PATH": "C:/ml/qnn_sdk/qairt/2.31.0.250130/",
   +        "BUILD_SHARED_LIBS": "OFF"
       }
   },
   ```

   > **Important**: Replace `C:/ml/qnn_sdk/qairt/2.31.0.250130/` with your actual QNN SDK path.

3. **Select Build Configuration**
   - In Visual Studio, select the `arm64-windows-llvm-debug` configuration from the dropdown
   
   ![Configuration Selection](https://github.com/user-attachments/assets/be4afbc8-78be-457d-9498-53fb7ec43578)

4. **Build the Project**
   - Go to `Build` → `Build All`
   - Output files will be located in `build-arm64-windows-llvm-debug/bin/`

### Build Output

After successful compilation, you'll find the following executables:
- `llama-cli.exe` - Main inference executable
- `llama-bench.exe` - Benchmarking tool
- `test-backend-ops.exe` - Backend operation tests
