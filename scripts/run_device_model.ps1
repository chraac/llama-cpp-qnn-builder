param (
    [string]$ModelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf',
    [switch]$Verbose,
    [switch]$PushToDevice,
    [string]$ExtraArgs = ''  # Add extraArgs parameter with default empty string
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deviceExecPath = '/data/local/tmp'
$deviceModelPath = '/data/local/tmp'

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
            if ($args[$args.IndexOf($arg) - 1] -notin @('-m', '--model-name', -v, '--verbose', '-p', '--push-to-device')) {
                Write-Host "Invalid option $arg"
                exit 1
            }
        }
    }
}

# Set ExtraArgs based on Verbose if not explicitly provided
if ($Verbose -and $ExtraArgs -eq '') {
    $ExtraArgs = "-v"
}

if ($PushToDevice) {
    & "$scriptPath/push_and_run_test.ps1" -p
}

$deviceCommandString = "cd $deviceExecPath && "
$deviceCommandString += "LLAMA_CACHE=./cache LD_LIBRARY_PATH=./ ADSP_LIBRARY_PATH=./ "
$deviceCommandString += "./llama-cli $ExtraArgs -m `"$deviceModelPath/$ModelName`" --no-mmap --color -i -r `"User:`""

adb shell $deviceCommandString