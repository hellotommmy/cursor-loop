$ErrorActionPreference = "SilentlyContinue"

$configPath = Join-Path $PSScriptRoot "..\..\loop-config.json"
if (-not (Test-Path $configPath)) {
    @'
{
  "decision": "stop",
  "followup_message": "loop-config.json not found. Create one in the workspace root. See README.md for the schema."
}
'@
    exit 0
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$task = $config.task

if (-not $task -or $task.Trim() -eq "") {
    @'
{
  "decision": "stop"
}
'@
    exit 0
}

$validationCmd = $config.validation_command
$validationShell = if ($config.validation_shell) { $config.validation_shell } else { "powershell" }
$onFail = if ($config.on_validation_fail) { $config.on_validation_fail } else { "Validation failed. Fix the errors:\n{errors}" }
$onPass = if ($config.on_validation_pass) { $config.on_validation_pass } else { "Validation passed." }

function Escape-Json($s) {
    $s -replace '\\', '\\\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n' -replace "`t", '\t'
}

$msg = ""

if ($validationCmd -and $validationCmd.Trim() -ne "") {
    if ($validationShell -eq "bash") {
        $output = & bash -c "$validationCmd" 2>&1
    } else {
        $output = Invoke-Expression $validationCmd 2>&1
    }
    $exitCode = $LASTEXITCODE
    $outputStr = ($output | Out-String).Trim()
    $escapedOutput = Escape-Json $outputStr

    if ($exitCode -ne 0) {
        $failMsg = $onFail -replace '\{errors\}', $escapedOutput
        $msg = Escape-Json $failMsg
        $msg += "\n\n"
    } else {
        $passMsg = Escape-Json $onPass
        $msg = "$passMsg\n\n"
    }
}

$escapedTask = Escape-Json $task
$msg += "ONGOING TASK (keep working on this):\n$escapedTask"

@"
{
  "decision": "continue",
  "followup_message": "$msg"
}
"@
