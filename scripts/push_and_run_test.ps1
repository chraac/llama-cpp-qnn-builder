
$_is_push_only = $false
$_device_path = '/data/local/tmp/'
$_script_path = Split-Path -Parent $MyInvocation.MyCommand.Path
$_build_path = "$_script_path/../build_qnn"

if ($args.Length -eq 1) {
    if ($args[0] -eq '-p') {
        $_is_push_only = $true
    }
}

Get-ChildItem -Path "$_build_path/*.so" | ForEach-Object { adb push $_.FullName $_device_path }

$executable_name = 'test-backend-ops'
$executable_full_path = "$_device_path$executable_name"

adb push "$_build_path/test-backend-ops" $_device_path
adb shell "chmod +x $executable_full_path"

if (Test-Path "$_build_path/lldb-server") {
    adb push "$_build_path/lldb-server" $_device_path
    adb shell "chmod +x ${_device_path}lldb-server"
} else {
    Write-Host -ForegroundColor Yellow "lldb-server not found in $_build_path"
}

if (Test-Path "$_build_path/gdbserver") {
    adb push "$_build_path/gdbserver" $_device_path
    adb shell "chmod +x ${_device_path}gdbserver"
} else {
    Write-Host -ForegroundColor Yellow "gdbserver not found in $_build_path"
}

if (!$_is_push_only) {
    Write-Host -ForegroundColor Green "Running tests GGML_OP_ADD ..."
    adb shell "$executable_full_path -o ADD"
    
    Write-Host -ForegroundColor Green "Running tests GGML_OP_MUL_MAT ..."
    adb shell "$executable_full_path -o MUL_MAT"
}
