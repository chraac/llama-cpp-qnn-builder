This guide describes how to build Android and Windows versions of the QNN backend for llama.cpp, enabling efficient inference on Qualcomm hardware.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Android Build](#android-build)
  - [Android Prerequisites](#android-prerequisites)
  - [Android Build Process](#android-build-process)
  - [Build Options](#build-options)
  - [Build Examples](#build-examples)
  - [Hexagon SDK Setup](#hexagon-sdk-setup)
    - [Prerequisites](#prerequisites)
    - [Building the Hexagon SDK Image with Local SDK Folder](#building-the-hexagon-sdk-image-with-local-sdk-folder)
- [Windows Build](#windows-build)
  - [Windows Prerequisites](#windows-prerequisites)
  - [Windows Build Process](#windows-build-process)
  - [Windows Build Output](#windows-build-output)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)

## Android Build

### Android Prerequisites

1. **Docker Engine**
   - Install following the [official Docker guide](https://docs.docker.com/engine/install/)
   - Ensure Docker Compose is included with your installation

2. **Source Code**
   - Clone the repository:
     ```bash
     git clone https://github.com/chraac/llama-cpp-qnn-builder.git
     cd llama-cpp-qnn-builder
     ```

> **Note**: Use the latest `main` branch as we're using NDK r27c with important optimization flags for Release builds.

### Android Build Process

1. **Basic Build**
   - Navigate to the project root directory:
     ```bash
     ./docker/docker_compose_compile.sh
     ```

2. **Build Output**
   - Executables will be in `build_qnn_arm64-v8a/bin/`
   - The console will show build progress and completion status:
   
   ![Build Output](https://github.com/user-attachments/assets/101a97be-efdf-455d-9d3c-a593311e144a)

### Build Options

| Parameter                   | Short | Description                                | Default             |
| --------------------------- | ----- | ------------------------------------------ | ------------------- |
| `--rebuild`                 | `-r`  | Force rebuild of the project               | `false`             |
| `--repo-dir`                |       | Specify llama.cpp repository directory     | `../llama.cpp`      |
| `--debug`                   | `-d`  | Build in Debug mode                        | `Release`           |
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
./docker/docker_compose_compile.sh

# Debug build with Hexagon NPU backend
./docker/docker_compose_compile.sh -d --enable-hexagon-backend

# Debug build with Hexagon NPU backend only
./docker/docker_compose_compile.sh -d --hexagon-npu-only

# Debug build with Hexagon NPU backend and quantized tensor support
./docker/docker_compose_compile.sh -d --hexagon-npu-only --enable-dequant

# QNN-only build with performance logging
./docker/docker_compose_compile.sh --qnn-only --perf-log

# Force rebuild with debug symbols
./docker/docker_compose_compile.sh -r -d
```

### Hexagon SDK Setup

To build with Hexagon NPU backend support, you need to create a Docker image that includes the Hexagon SDK.

#### Prerequisites

1. **Hexagon SDK**
   - Option 1: Download SDK from [Hexagon NPU SDK - Getting started](https://docs.qualcomm.com/bundle/publicresource/topics/80-77512-1/hexagon-dsp-sdk-getting-started.html?product=1601111740010422) (version **6.3.0.0** for Linux)
   - Option 2: Use an existing SDK installation

2. **Base Docker Image**
   - Required image: `chraac/llama-cpp-qnn-builder:2.36.0.250627-ndk-r27`
   - Contains Android NDK r27c and build tools

#### Building the Hexagon SDK Image with Local SDK Folder

If you already have the Hexagon SDK extracted on your machine:

1. **Create Dockerfile** (save as `Dockerfile.hexagon_sdk.local`):

   ```dockerfile
   FROM chraac/llama-cpp-qnn-builder:2.36.0.250627-ndk-r27

   ENV HEXAGON_SDK_VERSION='6.3.0.0'
   ENV HEXAGON_SDK_BASE=/local/mnt/workspace/Qualcomm/Hexagon_SDK
   ENV HEXAGON_SDK_PATH=${HEXAGON_SDK_BASE}/${HEXAGON_SDK_VERSION}
   ENV ANDROID_NDK_HOME=/android-ndk/android-ndk-r27c
   ENV ANDROID_ROOT_DIR=${ANDROID_NDK_HOME}/

   RUN mkdir -p ${HEXAGON_SDK_PATH}
   ARG LOCAL_SDK_PATH
   ADD ${LOCAL_SDK_PATH} ${HEXAGON_SDK_PATH}/6.3.0.0

   # Install required dependencies
   RUN apt update && apt install -y \
       python-is-python3 \
       libncurses5 \
       lsb-base \
       lsb-release \
       sqlite3 \
       rsync \
       git \
       build-essential \
       libc++-dev \
       clang \
       cmake

   # Dummy version info for hexagon-sdk 
   RUN echo 'VERSION_ID="20.04"' > /etc/os-release
   ```

2. **Create Setup Script** (save as `docker_compose_hexagon_local.sh`):

   ```bash
   #!/bin/bash

   # Check if SDK path is provided
   if [ -z "$1" ]; then
   echo "Usage: $0 /path/to/hexagon/sdk/6.3.0.0"
   exit 1
   fi

   SDK_PATH="$1"

   # Check if SDK path exists
   if [ ! -d "$SDK_PATH" ]; then
   echo "Error: SDK path does not exist: $SDK_PATH"
   exit 1
   fi

   # Build the Docker image with SDK embedded
   docker build -f Dockerfile.hexagon_sdk.local --build-arg LOCAL_SDK_PATH="$SDK_PATH" -t llama-cpp-qnn-hexagon:embedded .

   # Create a Docker Compose configuration file
   cat > docker-compose.hexagon.yml << EOF
   version: '3'
   services:
   hexagon-builder:
      image: llama-cpp-qnn-hexagon:embedded
      volumes:
         - ./:/workspace
      working_dir: /workspace
   EOF

   echo "Setup complete! Use the following command to compile with Hexagon support:"
   echo "./docker/docker_compose_compile.sh --enable-hexagon-backend"
   ```

3. **Run Setup**:

   ```bash
   chmod +x docker_compose_hexagon_local.sh
   ./docker_compose_hexagon_local.sh /path/to/your/Hexagon_SDK/6.3.0.0
   ```

4. **Build with Hexagon Support**:

   ```bash
   # Enable Hexagon NPU backend
   ./docker/docker_compose_compile.sh --enable-hexagon-backend
   
   # Or build with Hexagon NPU backend only
   ./docker/docker_compose_compile.sh --hexagon-npu-only
   
   # Access container shell for manual builds
   docker-compose -f docker-compose.hexagon.yml run --rm hexagon-builder bash
   ```

## Windows Build

### Windows Prerequisites

1. **Qualcomm AI Engine Direct SDK**
   - Download from [Qualcomm Developer Portal](https://www.qualcomm.com/developer/software/qualcomm-ai-engine-direct-sdk)
   - Extract to a folder (example: `C:/ml/qnn_sdk/qairt/2.31.0.250130/`)

2. **Visual Studio 2022**
   - Required components:
     - **Clang toolchain** for ARM64 compilation
       ![VS2022 Clang Installation](https://github.com/user-attachments/assets/30ee11f7-9069-4793-856d-c64bcd5d563b)
     
     - **CMake tools** for Visual Studio
       ![VS2022 CMake Installation](https://github.com/user-attachments/assets/9a36dde5-0e41-4421-9161-e9b09cd32eb1)

3. **Hexagon SDK** (optional, only for Hexagon NPU backend)
   - Follow [Hexagon NPU SDK - Getting started](https://docs.qualcomm.com/bundle/publicresource/topics/80-77512-1/hexagon-dsp-sdk-getting-started.html?product=1601111740010422)
   - Install Qualcomm Package Manager (QPM) first
   - Use QPM to install the Hexagon SDK
   - Set environment variable `HEXAGON_SDK_ROOT` to your installation directory

### Windows Build Process

1. **Open Project**
   - Launch Visual Studio 2022
   - Click `Continue without code`
   - Navigate to `File` → `Open` → `CMake`
   - Select `CMakeLists.txt` in the llama.cpp root directory

2. **Configure CMake**
   
   Edit `llama.cpp/CMakePresets.json` to modify the `arm64-windows-llvm` configuration:

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

   > **Important**: Replace the QNN SDK path with your actual installation path.

3. **Select Configuration**
   - Choose `arm64-windows-llvm-debug` configuration from the dropdown menu
   
   ![Configuration Selection](https://github.com/user-attachments/assets/be4afbc8-78be-457d-9498-53fb7ec43578)

4. **Build**
   - Select `Build` → `Build All`
   - Output will be in `build-arm64-windows-llvm-debug/bin/`

### Windows Build Output

After successful compilation, you'll have these executables:

- `llama-cli.exe` - Main inference executable
- `llama-bench.exe` - Benchmarking tool
- `test-backend-ops.exe` - Backend operation tests

## Troubleshooting

### Common Issues

1. **Docker Permission Issues**
   - Add your user to the docker group:
     ```bash
     sudo usermod -aG docker $USER
     # Log out and back in for changes to take effect
     ```

2. **Hexagon SDK Compatibility**
   - Verify you're using exactly version 6.3.0.0 of the SDK
   - Ensure SDK directory permissions allow Docker container access

3. **Build Failures**
   - Check Docker logs for detailed error messages:
     ```bash
     docker-compose -f docker-compose.hexagon.yml logs
     ```
