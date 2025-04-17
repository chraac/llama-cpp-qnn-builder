param (
    [string]$ModelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf',
    [switch]$Verbose,
    [switch]$PushToDevice
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deviceExecPath = '/data/local/tmp'
$deviceModelPath = '/data/local/tmp'
$extraArgs = ''

# Process non-parameter arguments for backward compatibility
foreach ($arg in $args) {
    switch ($arg) {
        '-m' { $ModelName = $args[$args.IndexOf($arg) + 1] }
        '--model-name' { $ModelName = $args[$args.IndexOf($arg) + 1] }
        '-v' { $Verbose = $true }
        '--verbose' { $Verbose = $true }
        '-p' { $PushToDevice = $true }
        '--push-to-device' { $PushToDevice = $true }
        default {
            # Skip argument values that follow parameter names
            if ($args[$args.IndexOf($arg) - 1] -notin @('-m', '--model-name')) {
                Write-Host "Invalid option $arg"
                exit 1
            }
        }
    }
}

if ($Verbose) {
    $extraArgs = "-v"
}

if ($PushToDevice) {
    & "$scriptPath/push_and_run_test.ps1" -p
}

# Build the device command string
$deviceCommandString = "cd $deviceExecPath && "
$deviceCommandString += "LLAMA_CACHE=./cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
$deviceCommandString += "./llama-cli $extraArgs -m `"$deviceModelPath/$ModelName`" --no-mmap --color -i -r `"User:`""

# Execute the ADB command
adb shell $deviceCommandString