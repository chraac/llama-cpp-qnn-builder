
# Parse command-line arguments
param (
    [string]$_modelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf',    
    [string]$_extraArgs = ''
)

$_scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$_deviceExecPath = '/data/local/tmp'
$_deviceModelPath = '/data/local/tmp'

# loop through the arguments
for ($i = 0; $i -lt $args.Length; $i++) {
    if ($args[$i] -eq '--model-name') {
        $_modelName = $args[$i + 1]
    } elseif ($args[$i] -eq '--verbose') {
        $_extraArgs = '-v '
    }
}

Write-Host "Model name: $_modelName"
Write-Host "Extra Arguments: $_extraArgs"

# Build the device command string
$deviceCommandString = "cd $_deviceExecPath && "
$deviceCommandString += "LLAMA_CACHE=$_deviceExecPath/cache "
$deviceCommandString += "./llama-cli $_extraArgs -m `"$_deviceModelPath/$_modelName`" --color -i -r `"User:`""

# Execute the ADB command
adb shell $deviceCommandString