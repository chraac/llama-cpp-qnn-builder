# llama-cpp-qnn-builder

Builder for llama.cpp with Qualcomm QNN (Qualcomm Neural Network) backend support, enabling efficient AI model inference on Snapdragon devices with Hexagon NPUs and Adreno GPUs.

[![Build and run tests](https://github.com/chraac/llama-cpp-qnn-builder/actions/workflows/build_and_run_tests.yml/badge.svg)](https://github.com/chraac/llama-cpp-qnn-builder/actions/workflows/build_and_run_tests.yml)

## Features

### Multiple Backend Options

- **QNN SDK Backend**: Official Qualcomm QNN SDK implementation for NPU acceleration
- **Hexagon NPU FastRPC Backend**: Custom-built from scratch using FastRPC framework for direct hardware control
- **ggml-hexagon**: Legacy Hexagon support
- **OpenCL**: Adreno GPU acceleration with custom kernels

### Platform Support

- **Android** (primary target) - ARM64 (arm64-v8a)
- **Windows on ARM** - Snapdragon devices
- **Linux** - Development and testing environment

### Advanced Hardware Acceleration

- Direct Hexagon NPU access with HVX intrinsics
- 4-thread parallel execution on NPU hardware
- Quantized tensor support (Q4_0, Q8_0, Q4_K)
- VTCM (Vector TCAM) memory optimization
- L2 cache-aware memory access patterns

## Quick Start

### Build for Android

```bash
# Basic build (default: Release mode with ggml-hexagon + QNN backends)
./docker/docker_compose_compile.sh

# Output will be in build_qnn_arm64-v8a/bin/
```

### Run on Device

```bash
# Push binaries and models to device, then run tests
./scripts/run_all_device_tests.sh -p

# Run a specific model
./build_qnn_arm64-v8a/bin/main -m models/meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_0.gguf -p "Hello"
```

## Build Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--rebuild` | `-r` | Force rebuild of the project | `false` |
| `--debug` | `-d` | Build in Debug mode | `Release` |
| `--build-linux-x64` | | Build for Linux x86_64 platform | `android arm64-v8a` |
| `--perf-log` | | Enable Hexagon performance tracking | `false` |
| `--hexagon-npu-only` | | Build Hexagon NPU backend only | `false` |
| `--qnn-only` | | Build QNN backend only | `false` |
| `--enable-dequant` | | Enable quantized tensor support in Hexagon | `false` |
| `--enable-ocl` | | Enable OpenCL support (Adreno kernels) | `false` |
| `--run-tests` | | Run backend operation tests after build | `false` |
| `--pull` | | Pull latest Docker image before build | `false` |

### Build Examples

```bash
# Debug build with Hexagon NPU backend and quantized tensor support
./docker/docker_compose_compile.sh -d --hexagon-npu-only --enable-dequant

# QNN-only build with performance logging
./docker/docker_compose_compile.sh --qnn-only --perf-log

# Disable ggml-hexagon, use QNN CPU backend instead
./docker/docker_compose_compile.sh --disable-ggml-hexagon

# Build with OpenCL support (Adreno kernels)
./docker/docker_compose_compile.sh --enable-ocl
```

## Testing

### Run All Device Tests

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

### Run Specific Model Tests

```bash
# Run Llama 3.2 1B test
./scripts/run_device_model_test.sh \
    -m "meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_0.gguf" \
    -t 512

# Run with verbose output and flash attention
./scripts/run_device_model_test.sh \
    -m "meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_0.gguf" \
    -v \
    -f
```

## Project Structure

```
llama-cpp-qnn-builder/
├── llama.cpp/               # Git submodule (fork of llama.cpp)
│   └── ggml/src/ggml-qnn/   # QNN backend implementation
│       ├── npu/            # Hexagon NPU FastRPC backend
│       │   ├── host/       # Host-side implementation
│       │   ├── device/     # Device-side implementation
│       │   └── idl/        # Interface Definition Language
│       └── shared/         # Shared QNN utilities
├── docker/                  # Docker build configuration
├── scripts/                 # Testing and utility scripts
├── models/                  # Pre-converted model files (GGUF format)
├── docs/                    # Documentation
└── build_qnn_*/             # Output directories for builds
```

## Documentation

- [How to Build](docs/how-to-build.md) - Detailed build instructions for Android and Windows
- [Hexagon NPU FastRPC Backend](docs/hexagon-npu.md) - Technical overview of the custom NPU implementation

## Model Support

The project includes pre-converted models in GGUF format:

- Meta Llama models (1B, 3B, 8B instruct variants)
- Qwen models (1.7B, 4B, 8B)
- DeepSeek models
- OpenAI GPT-OSS 20B

Models are available in both full precision (f16, bf16) and quantized formats (Q4_0, Q4_K_M, Q8_0).

## Technical Details

### Hexagon NPU FastRPC Backend

The Hexagon NPU backend is built entirely from scratch using Qualcomm's FastRPC framework:

- **Direct Hardware Access**: HVX intrinsics for critical operations
- **Zero-Copy Communication**: FastRPC and ION buffers for efficient data sharing
- **Custom Thread Pool**: 4-thread parallel execution matching NPU hardware capabilities
- **Graph-Level Execution**: Entire computation graphs executed on NPU to minimize transfers

### Key Advantages

- **Minimal Overhead**: FastRPC provides direct hardware access
- **Maximum Utilization**: Leverages all 4 NPU hardware threads
- **Power Efficiency**: 2-5x better performance-per-watt vs CPU
- **Flexible Architecture**: Supports both small and large model workloads

## Docker Images

- `chraac/llama-cpp-qnn-hexagon-builder` - Standard build with ggml-hexagon
- `chraac/llama-cpp-qnn-builder` - QNN-only build

## License

This project is built on top of [llama.cpp](https://github.com/ggerganov/llama.cpp), which is licensed under the MIT license.
