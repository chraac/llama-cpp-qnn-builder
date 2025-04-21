param (
    [switch]$PushToDevice,
    [string]$ExtraArgs = "test",
    [string]$LogFileName = "test-backend-ops_all"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$devicePath = '/data/local/tmp'
$logFileExtension = ".log"
$logFilePath = "$scriptPath/../run_logs/${LogFileName}${logFileExtension}"
$logcatOutputPath = "$scriptPath/../run_logs/${LogFileName}_logcat${logFileExtension}"
$extraRunVars = "LLAMA_CACHE=./cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./"

# Process non-parameter arguments for backward compatibility
foreach ($arg in $args) {
    switch ($arg) {
        '-p' { $PushToDevice = $true }
        '--push-to-device' { $PushToDevice = $true }
        '--extra-args' { 
            $ExtraArgs = $args[$args.IndexOf($arg) + 1]
        }
        '--log-file-name' { 
            $LogFileName = $args[$args.IndexOf($arg) + 1]
            $logFilePath = "$scriptPath/../run_logs/${LogFileName}${logFileExtension}"
            $logcatOutputPath = "$scriptPath/../run_logs/${LogFileName}_logcat${logFileExtension}"
        }
        default {
            if ($args[$args.IndexOf($arg) - 1] -notin @('--extra-args', '--log-file-name')) {
                Write-Error "Invalid option $arg"
                exit 1
            }
        }
    }
}

# Create logs directory if it doesn't exist
$logDir = Split-Path -Parent $logFilePath
if (!(Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

if ($PushToDevice) {
    & "$scriptPath/push_and_run_test.ps1" -p
}

# Clear logcat
adb logcat -c

# Start logcat in background process
$logcatProcess = Start-Process -FilePath "adb" -ArgumentList "logcat" -NoNewWindow -RedirectStandardOutput "$env:TEMP\logcat_temp.log" -PassThru

# Run the test command
$testCmd = "cd $devicePath && $extraRunVars ./test-backend-ops $ExtraArgs"
adb shell $testCmd 2>&1 | Out-File -FilePath $logFilePath

# Stop the logcat process
if ($null -ne $logcatProcess -and !$logcatProcess.HasExited) {
    $logcatProcess.Kill()
}

# Filter the logcat output and save to the output file
if (Test-Path "$env:TEMP\logcat_temp.log") {
    Get-Content "$env:TEMP\logcat_temp.log" | 
    Select-String -Pattern "adsprpc|pid-" | 
    Out-File -FilePath $logcatOutputPath
    Remove-Item "$env:TEMP\logcat_temp.log" -Force
}
