param (
    [Alias('-m')]
    [string]$ModelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf',

    [Alias('-v')]
    [switch]$Verbose,

    [Alias('-p')]
    [switch]$PushToDevice,
    
    [Alias('-e')]
    [switch]$ExtraPrompt,

    [Alias('-f')]
    [switch]$FlashAttention,

    [Alias('-t')]
    [string]$TokenCount = '512',
    
    [Alias('-l')]
    [string]$LogFileName = "llama-completion-test-llama3-1b-q4k-hexagon-npu-release"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deviceExecPath = '/data/local/tmp'
$deviceModelPath = '/sdcard'
$prompt = 'I believe the meaning of life is'
$promptLong = "You are an expert software engineer with deep knowledge of systems programming, machine learning, and distributed systems. Please analyze the following problem and provide a comprehensive solution. Question: I'm building a high-performance inference engine for large language models. The system needs to handle thousands of concurrent requests with low latency while maximizing GPU utilization. What architectural patterns should I consider? Context: Our current setup uses a simple request queue with a single model instance. Under high load, we see significant latency spikes and GPU memory fragmentation. The model is a 7B parameter transformer with 32 layers, 4096 hidden dimension, and 32 attention heads. We're using CUDA 12 with FlashAttention 2. Requirements: 1. P99 latency under 100ms for batch sizes up to 32 2. Support for both streaming and batch inference 3. Dynamic batching with timeout-based scheduling 4. Memory-efficient KV cache management 5. Graceful degradation under overload conditions Please provide: A detailed architecture design, key algorithms and data structures, memory optimization strategies, potential bottlenecks and mitigation approaches, and code examples for critical components."
$logFileExtension = ".log"
$logFilePath = "$scriptPath/../run_logs/${LogFileName}${logFileExtension}"
$logcatOutputPath = "$scriptPath/../run_logs/${LogFileName}_logcat${logFileExtension}"

$extraArgs = "-n $TokenCount --ignore-eos"
# Set extraArgs based on Verbose if not explicitly provided
if ($Verbose) {
    $extraArgs = "$extraArgs -v"
}

if ($PushToDevice) {
    & "$scriptPath/push_and_run_test.ps1" -p
}

if ($FlashAttention) {
    $extraArgs += " --flash-attn on"
}

Write-Host "ExtraArgs: $extraArgs"
Write-Host "LogFilePath: $logFilePath"

$promptString = ""
if ($ExtraPrompt) {
    $promptString = $promptLong
} else {
    $promptString = $prompt
}

$deviceCommandString = "cd $deviceExecPath && "
$deviceCommandString += "GGML_HEXAGON_EXPERIMENTAL=1 LLAMA_CACHE=$deviceExecPath/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
$deviceCommandString += "./llama-completion $extraArgs -m '$deviceModelPath/$ModelName' --fit on -no-cnv -s 1234 -c 4096 -p '$promptString'"

# Clear logcat
adb logcat -c

# Start logcat in background process
$logcatProcess = Start-Process -FilePath "adb" -ArgumentList "logcat" -NoNewWindow -RedirectStandardOutput "$env:TEMP\logcat_temp.log" -PassThru

# Run the test command
adb shell $deviceCommandString 2>&1 | Out-File -FilePath $logFilePath

# Stop the logcat process
if ($null -ne $logcatProcess -and !$logcatProcess.HasExited) {
    try {
        $logcatProcess.Kill()
    }
    catch {
        Write-Warning "Failed to kill logcat process: $($_.Exception.Message)"
    }
}

# Filter the logcat output and save to the output file
if (Test-Path "$env:TEMP\logcat_temp.log") {
    Get-Content "$env:TEMP\logcat_temp.log" | 
    Select-String -Pattern "adsprpc|pid-" | 
    Out-File -FilePath $logcatOutputPath
    Remove-Item "$env:TEMP\logcat_temp.log" -Force
}
