
param (
    [string]$_device_path = '/data/local/tmp/',
    [int]$_port = 23456,
    [string]$_parameters = 'test -o MUL_MAT',
    [switch]$_should_forward_port = $false,
    [string]$_executable_name = 'test-backend-ops'
)

# loop through the arguments
for ($i = 0; $i -lt $args.Length; $i++) {
    if ($args[$i] -eq '-p') {
        $_should_forward_port = $true
    }
    elseif ($args[$i] -eq '-exec') {
        $_executable_name = $args[$i + 1]
    }
    elseif ($args[$i] -eq '-params') {
        $_parameters = $args[$i + 1]
    }
}

$job = Start-job { adb shell $args[0] } -ArgumentList "cd $_device_path && ./gdbserver :$_port ./$_executable_name $_parameters"

if ($_should_forward_port) {
    adb forward tcp:$_port tcp:$_port
    adb forward --list
}

Wait-Job $job
Receive-job $job
