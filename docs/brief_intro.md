# Hexagon NPU FastRPC Backend for GGML

## Overview

The Hexagon NPU FastRPC backend provides hardware acceleration for GGML operations using Qualcomm's Hexagon NPU capabilities. This backend is **built entirely from scratch using Qualcomm's FastRPC framework**, providing a low-level alternative to QNN SDK-based implementations. By bypassing high-level abstractions and programming directly with HVX intrinsics, it is designed to offload compute-intensive operations from the CPU to Qualcomm's specialized Hexagon NPU hardware, enabling maximum performance and power efficiency for machine learning workloads on Snapdragon platforms.

## Key Features

### Custom FastRPC Implementation
- **Built from Scratch**: Complete custom implementation using Qualcomm's FastRPC framework for direct hardware control
- **Minimal Abstraction Layer**: Lightweight, efficient abstraction objects on the host side for seamless GGML graph/tensor/buffer offloading
- **Zero-Copy Communication**: FastRPC and ION buffers enable efficient data sharing between CPU and NPU domains

### Direct Hardware Programming
- **Raw HVX Intrinsics**: Critical operations like `mul_mat` and `add` implemented using direct Hexagon Vector Extensions
- **Custom Thread Pool**: 4-thread parallel execution matching NPU hardware capabilities with intelligent load balancing
- **VTCM Management**: Thread-specific VTCM operations that fully leverage high-speed VTCM to reduce memory bandwidth pressure
- **L2 Cache Optimization**: Prefetching and cache-aware memory access patterns for maximum bandwidth utilization

### Advanced Quantization Support
- **Hardware-Accelerated Formats**: Q4_0, Q8_0, Q4_K quantized data types with custom HVX dequantization functions
- **Mixed Precision Operations**: Support for quantized (Q4_0, Q8_0, Q4_K) and FP32 mixed operations with efficient conversion tables

## Supported Operations

### FastRPC Custom Kernels
- **Matrix Multiplication** (`mul_mat`): Custom HVX implementation with 4-thread parallelization for transformer workloads
- **Element-wise Operations**: Add, multiply operations with broadcasting support using direct HVX intrinsics
- **RMS Normalization**: Hand-optimized kernels for layer normalization operations common in modern LLMs
- **Graph-level Execution**: Entire computation graphs executed on NPU to minimize CPU-NPU memory transfers and maximize efficiency

## Platform Support

- **Android**: Primary target platform with Snapdragon SoCs featuring Hexagon NPU (8 Gen 1+, 8cx Gen 3+)
- **Linux**: Development and testing support for Hexagon-enabled platforms
- **Windows on ARM**: Cross-platform compatibility for Snapdragon-based Windows devices

## Key Advantages

- **Minimal Overhead**: FastRPC implementation provides direct hardware access with virtually no abstraction penalties
- **Maximum Hardware Utilization**: Custom implementation leverages all 4 hardware threads and HVX units on the Hexagon NPU
- **Memory Bandwidth Optimization**: Graph-level execution and zero-copy transfers reduce bottlenecks between CPU and NPU
- **Power Efficiency**: Direct NPU execution typically provides 2-5x better performance-per-watt compared to CPU execution
- **Scalable Architecture**: Designed to efficiently handle both small and large model workloads

## Technical Implementation

### Based on FastRPC Framework

#### Host Side (`ggml/src/ggml-qnn/npu/host/`)
- **Host Device Management**: [`host_device.cpp`](ggml/src/ggml-qnn/npu/host/host_device.cpp) - NPU device interface and lifecycle management
- **Host Graph Coordination**: [`host_graph.cpp`](ggml/src/ggml-qnn/npu/host/host_graph.cpp) - graph creation, caching, and execution coordination
- **Buffer Management**: [`buffer.cpp`](ggml/src/ggml-qnn/npu/host/buffer.cpp) - RPC memory buffers, ION allocation, and zero-copy data transfer
- **Type Conversion Utilities**: Efficient host-device data format conversion and RPC interface helpers

#### Device Side (`ggml/src/ggml-qnn/npu/device/`)
- **Device Runtime**: [`device.cpp`](ggml/src/ggml-qnn/npu/device/device.cpp) - core NPU-side runtime executing on Hexagon hardware
- **Graph Execution Engine**: [`graph.cpp`](ggml/src/ggml-qnn/npu/device/graph.cpp) - NPU-side graph computation with 4-thread parallelization
- **HVX Operation Kernels**: [`op_impl.cpp`](ggml/src/ggml-qnn/npu/device/op_impl.cpp) - hand-optimized HVX intrinsic implementations
- **Quantization Kernels**: [`quants.cpp`](ggml/src/ggml-qnn/npu/device/quants.cpp) - HVX-optimized dequantization for Q4_0, Q8_0, Q4_K
- **Thread Management**: [`thread_pool.hpp`](ggml/src/ggml-qnn/npu/device/thread_pool.hpp) - custom 4-thread pool using QURT primitives
- **Memory Management**: [`vtcm_mem.hpp`](ggml/src/ggml-qnn/npu/device/vtcm_mem.hpp) - VTCM allocation with RAII semantics

#### FastRPC Interface (`ggml/src/ggml-qnn/npu/idl/`)
- **Interface Definition**: [`hexagon_npu.idl`](ggml/src/ggml-qnn/npu/idl/hexagon_npu.idl) - defines the RPC contract between host CPU and Hexagon NPU

## Benchmark Results

TODO

## Future Developments

- **Extended Operation Coverage**: Additional custom HVX implementations for more GGML operations (attention, softmax, etc.)
- **Dynamic Thread Scheduling**: Runtime load balancing and work-stealing across the 4 hardware threads
- **Performance Profiling Suite**: Custom profiling tools for FastRPC execution paths and bottleneck analysis
- **Advanced Graph Fusion**: Sophisticated operation fusion techniques to minimize memory transfers and maximize NPU utilization
- **Model-Specific Optimizations**: Tailored kernel implementations for popular model architectures (Llama, Mistral, etc.)