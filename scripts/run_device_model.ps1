param (
    [Alias('-m')]
    [string]$ModelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf',

    [Alias('-v')]
    [switch]$Verbose,

    [Alias('-p')]
    [switch]$PushToDevice,

    [Alias('-f')]
    [switch]$FlashAttention
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deviceExecPath = '/data/local/tmp'
$deviceModelPath = '/sdcard'

$extraArgs = ""
# Set extraArgs based on Verbose if not explicitly provided
if ($Verbose) {
    $extraArgs = "-v"
}

if ($PushToDevice) {
    & "$scriptPath/push_and_run_test.ps1" -p
}

if ($FlashAttention) {
    $extraArgs += " --flash-attn"
}

$deviceCommandString = "cd $deviceExecPath && "
$deviceCommandString += "LLAMA_CACHE=$deviceExecPath/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
$deviceCommandString += "./llama-cli $extraArgs -m `"$deviceModelPath/$ModelName`" --no-mmap --color -i -r `"User:`""

adb shell $deviceCommandString