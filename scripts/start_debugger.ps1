
$_device_path = '/data/local/tmp/'
$_port = 23456
$_parameters = 'test -o MUL_MAT'
$_should_forward_port = $false

if ($args.Length -eq 1) {
    if ($args[0] -eq '-p') {
        $_should_forward_port = $true
    }
}

$job = Start-job { adb shell $args[0] } -ArgumentList "cd $_device_path && ./gdbserver :$_port ./test-backend-ops $_parameters"

if ($_should_forward_port) {
    adb forward tcp:$_port tcp:$_port
    adb forward --list
}

Wait-Job $job
Receive-job $job
