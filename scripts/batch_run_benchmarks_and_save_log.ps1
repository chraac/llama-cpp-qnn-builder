param (
    [string]$LogFileName = 'llama-bench-batch-qnn-gpu-debug.log',
    [switch]$PushToDevice,
    [switch]$Verbose,
    [switch]$Skip8b
)

$_scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$_devicePath = '/data/local/tmp'
$_deviceModelPath = '/sdcard'
$_modelList = @(
    'meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf', 
    'meta-llama_Meta-Llama-3.2-3B-Instruct-Q4_K_M.gguf', 
    'meta-llama_Meta-Llama-3-8B-Instruct-Q4_K_M.gguf'
)

# Parse non-parameter arguments for backward compatibility
foreach ($arg in $args) {
    switch ($arg) {
        '--log-file-name' { 
            $LogFileName = $args[$args.IndexOf($arg) + 1]
        }
        '--push-to-device' {
            $PushToDevice = $true
        }
        '--verbose' {
            $Verbose = $true
        }
        '--skip_8b' {
            $Skip8b = $true
        }
        default {
            # Skip argument values that follow parameter names
            if ($args[$args.IndexOf($arg) - 1] -ne '--log-file-name') {
                Write-Host "Invalid option $arg"
                exit 1
            }
        }
    }
}

if ($PushToDevice) {
    & "$_scriptPath/push_and_run_test.ps1" -p
}

if ($Skip8b) {
    $_modelList = @(
        'meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf', 
        'meta-llama_Meta-Llama-3.2-3B-Instruct-Q4_K_M.gguf'
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
    $commandString += "LLAMA_CACHE=./cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
    $commandString += "./llama-bench --progress ${extraArgs} -mmp 0 -p 512 -n 128 -m ${_deviceModelPath}/$modelName"
    adb shell "$commandString"
}

foreach ($model in $_modelList) {
    "Running benchmark for $model..." | Out-File -FilePath $logFilePath -Append
    Run-Benchmark -modelName $model 2>&1 | Out-File -FilePath $logFilePath -Append
}