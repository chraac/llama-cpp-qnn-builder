# How to Build llama.cpp with QNN Backend

This guide describes how to build Android and Windows versions of the QNN backend for llama.cpp, enabling efficient inference on Qualcomm hardware.

## Table of Contents

- [Android Build](#android-build)
  - [Prerequisites](#prerequisites)
  - [Quick Build](#quick-build)
  - [Build Options](#build-options)
  - [Build Examples](#build-examples)
  - [Build Output](#build-output)
  - [Testing on Device](#testing-on-device)
- [Hexagon SDK Setup](#hexagon-sdk-setup)
  - [Prerequisites](#hexagon-sdk-prerequisites)
  - [Building the Hexagon SDK Image](#building-the-hexagon-sdk-image)
- [Windows Build](#windows-build)
  - [Prerequisites](#windows-prerequisites)
  - [Build Process](#windows-build-process)
  - [Build Output](#windows-build-output)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)

---

## Android Build

### Prerequisites

1. **Docker Engine**
   - Install following the [official Docker guide](https://docs.docker.com/engine/install/)
   - Ensure Docker Compose is included with your installation

2. **Source Code**
   - Clone the repository:
     ```bash
     git clone https://github.com/chraac/llama-cpp-qnn-builder.git
     cd llama-cpp-qnn-builder
     ```

3. **Android Device (for testing)**
   - Snapdragon device with NPU support (8 Gen 1+, 8cx Gen 3+, or similar)
   - USB debugging enabled
   - `adb` command available on host system

> **Note**: Use the latest `main` branch as we're using NDK r27c with important optimization flags for Release builds.

### Quick Build

Navigate to the project root directory and run the build script:

```bash
./docker/docker_compose_compile.sh
```

This builds with default settings (Release mode, ggml-hexagon + QNN backends).

### Build Options

| Option                   | Short | Description                                      | Default             |
| ------------------------ | ----- | ------------------------------------------------ | ------------------- |
| `--rebuild`              | `-r`  | Force rebuild of the project                    | `false`             |
| `--repo-dir`             |       | Specify llama.cpp repository directory          | `../llama.cpp`      |
| `--debug`                | `-d`  | Build in Debug mode                             | `Release`           |
| `--asan`                 |       | Enable AddressSanitizer                         | `false`             |
| `--build-linux-x64`      |       | Build for Linux x86_64 platform                 | `android arm64-v8a` |
| `--perf-log`             |       | Enable Hexagon performance tracking             | `false`             |
| `--enable-hexagon-backend`|       | Enable Hexagon backend support                  | `true`              |
| `--disable-hexagon-backend`|      | Disable Hexagon backend support                 | `false`             |
| `--hexagon-npu-only`     |       | Build Hexagon NPU backend only                  | `false`             |
| `--disable-hexagon-and-qnn`|     | Disable both Hexagon and QNN backends          | `false`             |
| `--qnn-only`             |       | Build QNN backend only                           | `false`             |
| `--enable-dequant`       |       | Enable quantized tensor support in Hexagon      | `false`             |
| `--disable-ggml-hexagon` |       | Disable ggml-hexagon backend                    | `false`             |
| `--run-tests`            |       | Run backend operation tests after build         | `false`             |
| `--reset-submodules`     |       | Reset git submodules to clean state             | `false`             |
| `--ci`                   |       | Run in CI mode                                  | `false`             |
| `--pull`                 |       | Pull latest Docker image before build          | `false`             |
| `--enable-ocl`           |       | Enable OpenCL support (Adreno kernels)          | `false`             |

### Build Examples

```bash
# Basic build (default: Release mode, ggml-hexagon + QNN backends)
./docker/docker_compose_compile.sh

# Debug build
./docker/docker_compose_compile.sh -d

# Debug build with Hexagon NPU backend and quantized tensor support
./docker/docker_compose_compile.sh -d --hexagon-npu-only --enable-dequant

# QNN-only build with performance logging
./docker/docker_compose_compile.sh --qnn-only --perf-log

# Disable ggml-hexagon, use QNN CPU backend instead
./docker/docker_compose_compile.sh --disable-ggml-hexagon

# Build with OpenCL support (Adreno kernels)
./docker/docker_compose_compile.sh --enable-ocl

# Pull latest Docker image before building
./docker/docker_compose_compile.sh --pull

# Force rebuild with debug symbols
./docker/docker_compose_compile.sh -r -d

# Run backend tests after build (Linux x86_64)
./docker/docker_compose_compile.sh --build-linux-x64 --run-tests

# Disable all QNN/Hexagon backends (CPU only)
./docker/docker_compose_compile.sh --disable-hexagon-and-qnn
```

### Build Output

After successful build, executables will be in `build_qnn_arm64-v8a/bin/`:

- `test-backend-ops` - Backend operation tests
- `llama-cli` - Main inference executable
- `llama-completion` - Text completion executable
- `llama-bench` - Benchmarking tool
- `sysMonApp` - System monitoring application
- `*.so` - Shared library files for various backends

### Testing on Device

#### Push Binaries to Device

```bash
# Push binaries and run quick tests
./scripts/push_and_run_test.sh

# Push binaries only (no tests)
./scripts/push_and_run_test.sh -p
```

#### Run All Device Tests

```bash
# Push to device and run full test suite
./scripts/run_all_device_tests.sh -p

# Run benchmarks only
./scripts/run_all_device_tests.sh -p -b

# Run tests only (skip perf/model/benchmarks)
./scripts/run_all_device_tests.sh -p -t

# Use hexagon-npu backend instead of HTP0
./scripts/run_all_device_tests.sh -p -q
```

#### Run Specific Model Tests

```bash
# Run Llama 3.2 1B test with 512 tokens
./scripts/run_device_model_test.sh \
    -m "meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_0.gguf" \
    -t 512

# Run with verbose output and flash attention
./scripts/run_device_model_test.sh \
    -m "meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_0.gguf" \
    -v \
    -f
```

---

## Hexagon SDK Setup

To build with Hexagon NPU backend support, you need to create a Docker image that includes the Hexagon SDK.

### Hexagon SDK Prerequisites

1. **Base Docker Image**
   - Required image: `chraac/llama-cpp-qnn-builder:2.36.0.250627-ndk-r27`
   - Contains Android NDK r27c and build tools

### Building the Hexagon SDK Image

You can add the Hexagon SDK (community edition) URL to your docker image directly.

1. **Create Dockerfile** (save as `Dockerfile.hexagon_sdk.local`):

   ```dockerfile
   FROM chraac/llama-cpp-qnn-builder:2.36.0.250627-ndk-r27

   ENV HEXAGON_SDK_VERSION='6.3.0.0'
   ENV HEXAGON_SDK_BASE=/local/mnt/workspace/Qualcomm/Hexagon_SDK
   ENV HEXAGON_SDK_PATH=${HEXAGON_SDK_BASE}/${HEXAGON_SDK_VERSION}
   ENV ANDROID_NDK_HOME=/android-ndk/android-ndk-r27c
   ENV ANDROID_ROOT_DIR=${ANDROID_NDK_HOME}/

   RUN mkdir -p ${HEXAGON_SDK_PATH}
   ADD https://softwarecenter.qualcomm.com/api/download/software/sdks/Hexagon_SDK/Linux/Debian/${HEXAGON_SDK_VERSION}/Hexagon_SDK.zip /tmp/

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
       cmake \
       unzip

   # Unarchive Hexagon_SDK
   RUN unzip -o /tmp/Hexagon_SDK.zip -d ${HEXAGON_SDK_BASE}/../ && \
      rm -rf ${HEXAGON_SDK_BASE}/${HEXAGON_SDK_VERSION}/tools/android-ndk-*

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
   docker build -f Dockerfile.hexagon_sdk.local -t llama-cpp-qnn-hexagon:embedded .

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
   ./docker_compose_hexagon_local.sh
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

---

## Windows Build

### Prerequisites

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

### Build Process

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

### Build Output

After successful compilation, you'll have these executables:

- `llama-cli.exe` - Main inference executable
- `llama-bench.exe` - Benchmarking tool
- `test-backend-ops.exe` - Backend operation tests

---

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

4. **ADB Connection Issues**
   - Ensure USB debugging is enabled on the device
   - Check device connection with `adb devices`
   - Some devices require authorization popup when connecting via ADB

5. **NDK Version Issues**
   - Ensure you're using NDK r27c for optimal performance with Release builds
   - Use the `--pull` option to get the latest Docker image with updated NDK
