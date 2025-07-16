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
   ./docker/docker_compose_compile.sh
   ```

2. The console output will look similar to this, and executables will be located in `build_qnn_arm64-v8a/bin/`:
   ![Build Output](https://github.com/user-attachments/assets/101a97be-efdf-455d-9d3c-a593311e144a)

### Build Script Parameters

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

### How to create hexagon sdk build image

To build with Hexagon NPU backend support, you need to create a Docker image that includes the Hexagon SDK. This process requires downloading the Hexagon SDK manually due to licensing requirements.

#### SDK Download Requirements

1. **Download Hexagon SDK**
   - Visit the [Hexagon NPU SDK - Getting started](https://docs.qualcomm.com/bundle/publicresource/topics/80-77512-1/hexagon-dsp-sdk-getting-started.html?product=1601111740010422)
   - Download and install the Hexagon SDK version **6.3.0.0** for Linux

2. **Base Docker Image**
   - Ensure you have the base QNN builder image: `chraac/llama-cpp-qnn-builder:2.36.0.250627-ndk-r27`
   - This image includes Android NDK r27c and necessary build tools

#### Building the Hexagon SDK Image with Local SDK Folder

If you already have the Hexagon SDK extracted on your local machine, follow these steps:

1. **Create a new Dockerfile** (save as `Dockerfile.hexagon_sdk.local`):

   ```dockerfile
   FROM chraac/llama-cpp-qnn-builder:2.36.0.250627-ndk-r27

   ENV HEXAGON_SDK_VERSION='6.3.0.0'
   ENV HEXAGON_SDK_BASE=/local/mnt/workspace/Qualcomm/Hexagon_SDK
   ENV HEXAGON_SDK_PATH=${HEXAGON_SDK_BASE}/${HEXAGON_SDK_VERSION}
   ENV ANDROID_NDK_HOME=/android-ndk/android-ndk-r27c
   ENV ANDROID_ROOT_DIR=${ANDROID_NDK_HOME}/

   RUN mkdir -p ${HEXAGON_SDK_PATH}

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

2. **Build the Docker image with SDK folder mounted**:

   ```bash
   # Replace /path/to/your/Hexagon_SDK/6.3.0.0 with your actual SDK path
   docker build -f Dockerfile.hexagon_sdk.local -t llama-cpp-qnn-hexagon:local .
   
   # Run the container with the SDK directory mounted
   docker run -it --rm \
     -v /path/to/your/Hexagon_SDK/6.3.0.0:/local/mnt/workspace/Qualcomm/Hexagon_SDK/6.3.0.0 \
     llama-cpp-qnn-hexagon:local bash
   ```

3. **Create a convenience script** (save as `docker_compose_hexagon_local.sh`):

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
   
   # Build the Docker image
   docker build -f Dockerfile.hexagon_sdk.local -t llama-cpp-qnn-hexagon:local .
   
   # Create a Docker Compose configuration file
   cat > docker-compose.hexagon.yml << EOF
   version: '3'
   services:
     hexagon-builder:
       image: llama-cpp-qnn-hexagon:local
       volumes:
         - $SDK_PATH:/local/mnt/workspace/Qualcomm/Hexagon_SDK/6.3.0.0
         - ./:/workspace
       working_dir: /workspace
   EOF
   
   echo "Setup complete! Use the following command to compile with Hexagon support:"
   echo "./docker/docker_compose_compile.sh --enable-hexagon-backend"
   ```

   Make the script executable:
   ```bash
   chmod +x docker_compose_hexagon_local.sh
   ```

4. **Run the setup script**:

   ```bash
   ./docker_compose_hexagon_local.sh /path/to/your/Hexagon_SDK/6.3.0.0
   ```

#### Using the Hexagon SDK Image

Once the image is built with your local SDK mounted, you can use it for compiling llama.cpp with Hexagon NPU backend support:

```bash
# Build with Hexagon NPU backend enabled
./docker/docker_compose_compile.sh --enable-hexagon-backend

# Build with Hexagon NPU backend only
./docker/docker_compose_compile.sh --hexagon-npu-only

# Build with quantized tensor support
./docker/docker_compose_compile.sh --hexagon-npu-only --enable-dequant
```

You can also enter the container directly for debugging or manual builds:

```bash
docker-compose -f docker-compose.hexagon.yml run --rm hexagon-builder bash
```

## Windows

### Windows Prerequisites

1. **Download Qualcomm AI Engine Direct SDK**
   - Get it from [Qualcomm Developer Portal](https://www.qualcomm.com/developer/software/qualcomm-ai-engine-direct-sdk)
   - Extract to a folder (e.g., `C:/ml/qnn_sdk/qairt/2.31.0.250130/`)

2. **Install Visual Studio 2022**
   - Ensure the following components are installed:
     - **Clang toolchain** for ARM64 compilation

        ![VS2022 Clang Installation](https://github.com/user-attachments/assets/30ee11f7-9069-4793-856d-c64bcd5d563b)

     - **CMake tools** for Visual Studio

        ![VS2022 CMake Installation](https://github.com/user-attachments/assets/9a36dde5-0e41-4421-9161-e9b09cd32eb1)

3. **Install Hexagon SDK (for Hexagon NPU backend)**
   - To compile the `hexagon-npu` backend, you need to install the latest Hexagon SDK
   - Follow the [Hexagon NPU SDK - Getting started](https://docs.qualcomm.com/bundle/publicresource/topics/80-77512-1/hexagon-dsp-sdk-getting-started.html?product=1601111740010422):
     1. First install the Qualcomm Package Manager (QPM)
     2. Then use QPM to install the Hexagon SDK
   - Set the environment variable `HEXAGON_SDK_ROOT` to point to your installation directory

   > **Note**: The Hexagon SDK is only required if you plan to build with `--enable-hexagon-backend` or `--hexagon-npu-only` flags.

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
