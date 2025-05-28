param (
    [Alias('-m')]
    [string]$ModelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_K_M.gguf',

    [Alias('-v')]
    [switch]$Verbose,

    [Alias('-p')]
    [switch]$PushToDevice,

    [Alias('-e')]
    [string]$ExtraArgs = '', # Add extraArgs parameter with default empty string

    [Alias('-f')]
    [switch]$FlashAttention
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deviceExecPath = '/data/local/tmp'
$deviceModelPath = '/sdcard'

# Set ExtraArgs based on Verbose if not explicitly provided
if ($Verbose) {
    $ExtraArgs = "-v"
}

if ($PushToDevice) {
    & "$scriptPath/push_and_run_test.ps1" -p
}

if ($FlashAttention) {
    $ExtraArgs += " --flash-attn"
}

$deviceCommandString = "cd $deviceExecPath && "
$deviceCommandString += "LLAMA_CACHE=$deviceExecPath/.cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
$deviceCommandString += "./llama-cli $ExtraArgs -m `"$deviceModelPath/$ModelName`" --no-mmap --color -i -r `"User:`""

adb shell $deviceCommandString