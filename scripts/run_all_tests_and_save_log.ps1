
param (
    [switch]$_pushToDevice = $false
)

$_scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$_devicePath = '/data/local/tmp'
$_logFilePath = "$_scriptPath/../run_logs/test-backend-ops_all.log"

# Check arguments if not using named parameters
foreach ($arg in $args) {
    if ($arg -eq '--push-to-device') {
        $_pushToDevice = $true
    } else {
        Write-Error "Invalid option $arg"
        exit 1
    }
}

# Create logs directory if it doesn't exist
$logDir = Split-Path -Parent $_logFilePath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

if ($_pushToDevice) {
    & "$_scriptPath/push_and_run_test.ps1" -p
}

# Run the test and redirect output to log file
$commandString = "cd $_devicePath && LLAMA_CACHE=$_devicePath/cache ./test-backend-ops test"
adb shell $commandString 2>&1 | Out-File -FilePath $_logFilePath
