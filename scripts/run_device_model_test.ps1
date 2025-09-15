param (
    [Alias('-m')]
    [string]$ModelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf',

    [Alias('-v')]
    [switch]$Verbose,

    [Alias('-p')]
    [switch]$PushToDevice,

    [Alias('-f')]
    [switch]$FlashAttention,

    [Alias('-t')]
    [string]$TokenCount = '512',
    
    [Alias('-l')]
    [string]$LogFileName = "llama-cli-test-llama3-1b-q4k-hexagon-npu-release"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deviceExecPath = '/data/local/tmp'
$deviceModelPath = '/sdcard'
$prompt = 'I believe the meaning of life is'
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

$deviceCommandString = "cd $deviceExecPath && "
$deviceCommandString += "LLAMA_CACHE=$deviceExecPath/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
$deviceCommandString += "./llama-cli $extraArgs -m '$deviceModelPath/$ModelName' --no-mmap -no-cnv -s 1234 -p '$prompt'"

# Clear logcat
adb logcat -c

# Start logcat in background process
$logcatProcess = Start-Process -FilePath "adb" -ArgumentList "logcat" -NoNewWindow -RedirectStandardOutput "$env:TEMP\logcat_temp.log" -PassThru

# Run the test command
adb shell $deviceCommandString 2>&1 | Out-File -FilePath $logFilePath

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
