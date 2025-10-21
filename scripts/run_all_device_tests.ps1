param (
    [Alias('-p')] 
    [switch]$PushToDevice,
    
    [Alias('-b')]
    [switch]$BenchmarksOnly,
    
    [Alias('-t')]
    [switch]$TestOnly,

    [Alias('-r')]
    [string]$Revision,

    [Alias('-s')]
    [string]$Subdirectory
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($PushToDevice) {
    & "$scriptPath/push_and_run_test.ps1" -p
}

if (-not $BenchmarksOnly) {
    $testLogName = "test-backend-ops-all-release.hexagon.$Revision"
    if ($Subdirectory) {
        $testLogName = "$Subdirectory/$testLogName"
    }

    & "$scriptPath/run_all_tests_and_save_log.ps1" -e:"test -b hexagon-npu" -l:"$testLogName"
}

if (-not $TestOnly) {
    $perfLogName = "test-backend-ops-all-release.hexagon.$Revision"
    $modelTestLogName = "llama-cli-test-llama3-1b-q4-hexagon-npu-fa-512-release.$Revision"
    $benchmarkLogName = "llama-bench-batch-llama3-q4-hexagon-npu-release-no8bit.$Revision"
    if ($Subdirectory) {
        $perfLogName = "$Subdirectory/$perfLogName"
        $modelTestLogName = "$Subdirectory/$modelTestLogName"
        $benchmarkLogName = "$Subdirectory/$benchmarkLogName"
    }

    & "$scriptPath/run_all_tests_and_save_log.ps1" -e:"perf -b hexagon-npu" -l:"$perfLogName"
    & "$scriptPath/run_device_model_test.ps1" -f -m:"meta-llama_Meta-Llama-3.2-1B-Instruct-Q4_0.gguf" -l:"$modelTestLogName" -t:512
    & "$scriptPath/batch_run_benchmarks_and_save_log.ps1" -l:"$benchmarkLogName" -s -f
}