param (
    [Alias('-p')] 
    [switch]$PushToDevice,
    
    [Alias('-l')]
    [string]$LogFileName = 'llama-bench-batch-qnn-gpu-debug.log',
    
    [Alias('-v')]
    [switch]$Verbose,
    
    [Alias('-s')]
    [switch]$Skip8b
)

$_scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$_devicePath = '/data/local/tmp'
$_deviceModelPath = '/sdcard'
$_modelList = @(
    'meta-llama_Meta-Llama-3.2-1B-Instruct', 
    'meta-llama_Meta-Llama-3.2-3B-Instruct', 
    'meta-llama_Meta-Llama-3-8B-Instruct'
)

if ($PushToDevice) {
    & "$_scriptPath/push_and_run_test.ps1" -p
}

if ($Skip8b) {
    $_modelList = @(
        'meta-llama_Meta-Llama-3.2-1B-Instruct', 
        'meta-llama_Meta-Llama-3.2-3B-Instruct'
    )
}

$extraArgs = ""
if ($Verbose) {
    $extraArgs = "-v"
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
    $commandString += "./llama-bench --progress ${extraArgs} -mmp 0 -p 512 -n 128 -m ${_deviceModelPath}/$modelName"
    adb shell "$commandString"
}

foreach ($model in $_modelList) {
    $_model_q4_0 = "$model-Q4_0.gguf"
    "Running benchmark for $_model_q4_0..." | Out-File -FilePath $logFilePath -Append
    Run-Benchmark -modelName $_model_q4_0 2>&1 | Out-File -FilePath $logFilePath -Append

    $_model_q4_k_m = "$model-Q4_K_M.gguf"
    "Running benchmark for $_model_q4_k_m..." | Out-File -FilePath $logFilePath -Append
    Run-Benchmark -modelName $_model_q4_k_m 2>&1 | Out-File -FilePath $logFilePath -Append
}