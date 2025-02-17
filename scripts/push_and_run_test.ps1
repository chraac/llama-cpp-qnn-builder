
$_is_push_only = $false
$_device_path = '/data/local/tmp'
$_script_path = Split-Path -Parent $MyInvocation.MyCommand.Path
$_build_path = "$_script_path/../build_qnn_arm64-v8a"

if ($args.Length -eq 1) {
    if ($args[0] -eq '-p') {
        $_is_push_only = $true
    }
}

Get-ChildItem -Path "$_build_path/*.so" | ForEach-Object { adb push $_.FullName "$_device_path/" }

function Push-Executable {
    param (
        $exec_name
    )
    
    $exec_full_path = "$_device_path/$exec_name"
    adb push "$_build_path/$exec_name" "$_device_path/"
    adb shell "chmod +x $exec_full_path"
}

Push-Executable 'test-backend-ops'
Push-Executable 'llama-cli'
Push-Executable 'llama-bench'

function Push-Debug-Server {
    param (
        $server_name
    )
    
    if (Test-Path "$_build_path/$server_name") {
        adb push "$_build_path/$server_name" "$_device_path/"
        adb shell "chmod +x $_device_path/$server_name"
    }
    else {
        Write-Host -ForegroundColor Red "$server_name not found in $_build_path"
    }
}

Push-Debug-Server 'lldb-server'
Push-Debug-Server 'gdbserver'

if (!$_is_push_only) {
    Write-Host -ForegroundColor Green "Running tests GGML_OP_ADD ..."
    adb shell "$executable_full_path -o ADD"
    
    Write-Host -ForegroundColor Green "Running tests GGML_OP_MUL_MAT ..."
    adb shell "$executable_full_path -o MUL_MAT"
}
