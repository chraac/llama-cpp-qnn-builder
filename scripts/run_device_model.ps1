$_scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$_deviceExecPath = '/data/local/tmp'
$_deviceModelPath = '/data/local/tmp'
$_modelName = 'meta-llama_Meta-Llama-3.2-1B-Instruct-f32.gguf'
$_extraArgs = ''

# Parse command-line arguments
param (
    [Parameter(Mandatory = $false)]
    [string]$ModelName,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Process named parameters if provided
if ($ModelName) {
    $_modelName = $ModelName
}

if ($Verbose) {
    $_extraArgs = "-v"
}

# Build the device command string
$deviceCommandString = "cd $_deviceExecPath && "
$deviceCommandString += "LLAMA_CACHE=$_deviceExecPath/cache "
$deviceCommandString += "./llama-cli $_extraArgs -m `"$_deviceModelPath/$_modelName`" --color -i -r `"User:`""

# Execute the ADB command
adb shell $deviceCommandString