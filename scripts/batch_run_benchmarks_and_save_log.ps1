param (
    [Alias('-p')] 
    [switch]$PushToDevice,
    
    [Alias('-l')]
    [string]$LogFileName = 'llama-bench-batch-qnn-gpu-debug.log',
    
    [Alias('-v')]
    [switch]$Verbose,
    
    [Alias('-s')]
    [switch]$Skip8b,

    [Alias('-f')]
    [switch]$FlashAttention
)

$_scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$_devicePath = '/data/local/tmp'
$_deviceModelPath = '/sdcard'
$_modelList = @(
    'qwen3.5-2b-bf16', 
    'qwen3.5-4b-bf16', 
    'qwen3.5-9b-bf16'
)

if ($PushToDevice) {
    & "$_scriptPath/push_and_run_test.ps1" -p
}

if ($Skip8b) {
    $_modelList = @(
        'qwen3.5-2b-bf16', 
        'qwen3.5-4b-bf16'
    )
}

$extraArgs = ""
if ($Verbose) {
    $extraArgs = "-v"
}

if ($FlashAttention) {
    $extraArgs += " --flash-attn on"
}

$logFilePath = "$_scriptPath/../run_logs/$LogFileName"

# Create logs directory if it doesn't exist
$logDir = Split-Path -Parent $logFilePath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Run-Benchmark {
    param (
        [string]$modelName
    )
    
    $commandString = "cd $_devicePath && "
    $commandString += "LLAMA_CACHE=$_devicePath/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
    $commandString += "./llama-bench --progress ${extraArgs} -mmp 0 -r 20 -p 512 -n 128 -m ${_deviceModelPath}/$modelName"
    adb shell "$commandString"
}

foreach ($model in $_modelList) {
    $_model_q4_0 = "$model-q4.gguf"
    "Running benchmark for $_model_q4_0..." | Out-File -FilePath $logFilePath -Append
    Run-Benchmark -modelName $_model_q4_0 2>&1 | Out-File -FilePath $logFilePath -Append
}