#Requires -Version 5.1
<#
.SYNOPSIS
  Godot project smoke test: headless load, static checks, gdUnit4 test/.

.DESCRIPTION
  Minimal CLI regression gate before commit/PR. Does not replace F6/F5 manual QA.

.PARAMETER GodotBinary
  Godot executable path. Falls back to $env:GODOT_BIN, then known install paths.

.PARAMETER SkipStaticChecks
  Skip BOM and ext_resource static checks.

.PARAMETER SkipUnitTests
  Skip gdUnit4 test/ execution.

.PARAMETER FullStaticChecks
  Scan ext_resource paths in all .tscn files (slower; suited for CI/nightly).

.PARAMETER QuitAfterFrames
  Godot --quit-after value for headless load steps. Default 3 for init buffer.

.PARAMETER RetryOnFailure
  Retry failed Godot headless steps once (helps flaky first-import runs in CI).

.PARAMETER LogDir
  Directory for Godot step logs. Default: reports/smoke_logs under project root.

.PARAMETER SelfTest
  Run infrastructure self-tests only (quoting cases, runtime probe, env round-trip). No Godot smoke.

.EXAMPLE
  .\scripts\verify\run_smoke.ps1

.EXAMPLE
  .\scripts\verify\run_smoke.ps1 -FullStaticChecks -RetryOnFailure

.EXAMPLE
  .\scripts\verify\run_smoke.ps1 -SelfTest
#>
[CmdletBinding()]
param(
    [string] $GodotBinary = "",
    [switch] $SkipStaticChecks,
    [switch] $SkipUnitTests,
    [switch] $FullStaticChecks,
    [switch] $RetryOnFailure,
    [switch] $SelfTest,
    [int] $QuitAfterFrames = 3,
    [string] $LogDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$KeyScenes = @(
    "res://game_lobby.tscn",
    "res://test_arena.tscn",
    "res://survivors_game.tscn"
)
$KeySceneFiles = @(
    "game_lobby.tscn",
    "test_arena.tscn",
    "survivors_game.tscn"
)
$ExtResourcePattern = 'path="(res://[^"]+)"'
$GodotCriticalErrorPattern = 'Parse Error|SCRIPT ERROR|Failed to load|Invalid project path'
$GodotBenignExitNoisePattern = 'were leaked at exit|still in use at exit|ObjectDB instances leaked'
$DefaultGodotMajorMinor = "4.5"

if ([string]::IsNullOrWhiteSpace($LogDir)) {
    $LogDir = Join-Path $ProjectRoot "reports\smoke_logs"
}

$script:StepResults = @()
$script:ProcessArgumentListSupported = $null
$script:NativeProcessModeUsed = "unknown"

function New-SmokeStepResult {
    param(
        [string] $Name,
        [bool] $Passed,
        [int] $ExitCode = 0,
        [int] $ErrorLines = 0,
        [long] $DurationMs = 0,
        [string] $LogPath = "",
        [string] $Detail = ""
    )

    [PSCustomObject]@{
        Name       = $Name
        Passed     = $Passed
        ExitCode   = $ExitCode
        ErrorLines = $ErrorLines
        DurationMs = $DurationMs
        LogPath    = $LogPath
        Detail     = $Detail
    }
}

function Write-SmokeStepResult {
    param(
        [Parameter(Mandatory = $true)]
        $Result
    )

    $script:StepResults += $Result
    $suffix = ""
    if ($Result.DurationMs -gt 0) {
        $suffix = " ({0}ms" -f $Result.DurationMs
        if ($Result.ExitCode -ne 0) {
            $suffix += ", exit=$($Result.ExitCode)"
        }
        if ($Result.ErrorLines -gt 0) {
            $suffix += ", errors=$($Result.ErrorLines)"
        }
        $suffix += ")"
    }

    if ($Result.Passed) {
        Write-Host "[PASS] $($Result.Name)$suffix" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $($Result.Name)$suffix" -ForegroundColor Red
        if ($Result.Detail) {
            Write-Host "  $($Result.Detail)" -ForegroundColor DarkRed
        }
        if ($Result.LogPath -and (Test-Path -LiteralPath $Result.LogPath)) {
            Write-Host "  log: $($Result.LogPath)" -ForegroundColor DarkGray
        }
    }
}

function Write-SmokeSkip {
    param([string] $Name)
    Write-Host "[SKIP] $Name" -ForegroundColor DarkYellow
}

function Get-SafeEnvPath {
    param([string] $Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }
    return $value
}

function Get-GodotCandidatePaths {
    param([string] $OverridePath)

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($OverridePath)) {
        $candidates += $OverridePath
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_BIN)) {
        $candidates += $env:GODOT_BIN
    }

    $programFilesX86 = Get-SafeEnvPath "ProgramFiles(x86)"
    if ($programFilesX86) {
        $candidates += Join-Path $programFilesX86 "Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
    }

    $programFiles = Get-SafeEnvPath "ProgramFiles"
    if ($programFiles) {
        $candidates += Join-Path $programFiles "Godot\godot.windows.opt.tools.64.exe"
    }

    $localAppData = Get-SafeEnvPath "LOCALAPPDATA"
    if ($localAppData) {
        $candidates += Join-Path $localAppData "Programs\Godot\Godot_v4.5.2-stable_win64.exe"
    }

    return @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Resolve-GodotBinary {
    param([string] $OverridePath)

    foreach ($candidate in Get-GodotCandidatePaths -OverridePath $OverridePath) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $attempted = (Get-GodotCandidatePaths -OverridePath $OverridePath) -join "; "
    $fail = New-SmokeStepResult -Name "Resolve Godot binary" -Passed $false -Detail "Set GODOT_BIN or pass -GodotBinary. Tried: $attempted"
    Write-SmokeStepResult -Result $fail
    exit 1
}

function Get-GodotVersionFromExe {
    param([string] $GodotExe)

    $run = Invoke-NativeProcess -FilePath $GodotExe -ArgumentList @("--version") -WorkingDirectory $ProjectRoot
    $versionLine = @($run.Output | Select-Object -First 1) -join ""
    if ($versionLine -match '^([0-9]+\.[0-9]+)') {
        return @{
            MajorMinor = $Matches[1]
            Line       = $versionLine
            ExitCode   = $run.ExitCode
        }
    }
    return @{
        MajorMinor = $null
        Line       = $versionLine
        ExitCode   = $run.ExitCode
    }
}

function Get-ExpectedGodotMajorMinor {
    param([string] $GodotExe)

    $projectFile = Join-Path $ProjectRoot "project.godot"
    if (-not (Test-Path -LiteralPath $projectFile)) {
        $fail = New-SmokeStepResult -Name "Read project.godot" -Passed $false -Detail "Missing: $projectFile"
        Write-SmokeStepResult -Result $fail
        exit 1
    }

    $content = Get-Content -LiteralPath $projectFile -Raw
    $featurePatterns = @(
        'config/features=PackedStringArray\("([0-9]+\.[0-9]+)"',
        'config/features=PackedStringArray\([^)]*"([0-9]+\.[0-9]+)"',
        '"([0-9]+\.[0-9]+)"\s*,\s*"Forward Plus"'
    )

    foreach ($pattern in $featurePatterns) {
        if ($content -match $pattern) {
            return @{
                MajorMinor = $Matches[1]
                Source     = "project.godot config/features"
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($GodotExe)) {
        $fromExe = Get-GodotVersionFromExe -GodotExe $GodotExe
        if ($fromExe.MajorMinor) {
            Write-Host "[WARN] config/features parse failed; using Godot --version ($($fromExe.Line))" -ForegroundColor DarkYellow
            return @{
                MajorMinor = $fromExe.MajorMinor
                Source     = "Godot --version fallback"
            }
        }
    }

    Write-Host "[WARN] config/features parse failed; using default $DefaultGodotMajorMinor.x" -ForegroundColor DarkYellow
    return @{
        MajorMinor = $DefaultGodotMajorMinor
        Source     = "script default fallback"
    }
}

function Write-LogFile {
    param(
        [string] $Path,
        [string[]] $Lines
    )

    $text = ($Lines -join [Environment]::NewLine)
    [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
}

function New-SmokeLogPath {
    param([string] $StepName)

    if (-not (Test-Path -LiteralPath $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $safeName = ($StepName -replace '[^\w\-]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($safeName)) {
        $safeName = "step"
    }
    return Join-Path $LogDir ("{0}_{1:yyyyMMdd_HHmmss_fff}.log" -f $safeName, (Get-Date))
}

# Windows CommandLineToArgv escaping (backslash + quote rules). PS 5.1 / .NET Framework compatible.
# PS 7+ / .NET Core+ can use ProcessStartInfo.ArgumentList via Invoke-NativeProcess when available.
function Get-EscapedProcessArgument {
    param([string] $Argument)

    if ($null -eq $Argument) {
        return '""'
    }

    $needsQuotes = $false
    if ($Argument.Length -eq 0) {
        return '""'
    }

    foreach ($char in @(' ', "`t", "`n", "`v", '"')) {
        if ($Argument.Contains($char)) {
            $needsQuotes = $true
            break
        }
    }
    if (-not $needsQuotes) {
        return $Argument
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    $index = 0
    while ($index -lt $Argument.Length) {
        $backslashCount = 0
        while ($index -lt $Argument.Length -and $Argument[$index] -eq '\') {
            $backslashCount++
            $index++
        }

        if ($index -ge $Argument.Length) {
            [void]$builder.Append('\', ($backslashCount * 2))
        }
        elseif ($Argument[$index] -eq '"') {
            [void]$builder.Append('\', (($backslashCount * 2) + 1))
            [void]$builder.Append('"')
            $index++
        }
        else {
            if ($backslashCount -gt 0) {
                [void]$builder.Append('\', $backslashCount)
            }
            [void]$builder.Append($Argument[$index])
            $index++
        }
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Get-NativeProcessModeLabel {
    if (Test-ProcessArgumentListSupported) {
        return "ArgumentList"
    }
    return "EscapedArguments"
}

function Get-SmokeRuntimeInfo {
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $dotnetVersion = [System.Environment]::Version.ToString()
    $argumentListApi = Test-ProcessArgumentListSupported
    $nativeMode = Get-NativeProcessModeLabel

    return [PSCustomObject]@{
        PowerShellVersion   = $psVersion
        DotNetVersion       = $dotnetVersion
        ArgumentListApi     = $argumentListApi
        NativeProcessMode   = $nativeMode
        LastNativeProcessMode = $script:NativeProcessModeUsed
    }
}

function Write-SmokeRuntimeBanner {
    $info = Get-SmokeRuntimeInfo
    Write-Host ("runtime: PS={0} .NET={1} argumentlist_api={2} native_process={3}" -f `
            $info.PowerShellVersion, $info.DotNetVersion, $info.ArgumentListApi, $info.NativeProcessMode) `
        -ForegroundColor DarkGray
}

function Test-SmokeQuotingSelfTest {
    $failures = @()

    $escapeCases = @(
        @{ Name = "plain"; Input = "plain"; Expected = "plain" }
        @{ Name = "space"; Input = "has space"; Expected = '"has space"' }
        @{ Name = "parens"; Input = "C:\Program Files (x86)\app"; Expected = '"C:\Program Files (x86)\app"' }
        @{ Name = "embedded_quote"; Input = 'say "hi"'; Expected = '"say \"hi\""' }
        @{ Name = "trailing_backslash"; Input = "C:\Program Files\app\"; Expected = '"C:\Program Files\app\\"' }
        @{ Name = "backslash_before_quote"; Input = 'path\"x'; Expected = '"path\\\"x"' }
    )

    foreach ($case in $escapeCases) {
        $actual = Get-EscapedProcessArgument -Argument $case.Input
        if ($actual -ne $case.Expected) {
            $failures += ("quoting:{0} input=[{1}] expected=[{2}] actual=[{3}]" -f `
                    $case.Name, $case.Input, $case.Expected, $actual)
        }
    }

    return $failures
}

function New-SmokeSelfTestArtifacts {
    # 임시 프로브: direct ps(Invoke-NativeProcess) + cmd/gdUnit-like + cmd/edge argv round-trip
    # OutPath는 SMOKE_ARGV_OUT env로 전달(cmd %1 경로 quoting 회피). gdUnit-like 배치는 -Command로
    # -a 등 powershell 스위치 충돌을 피한다(runtest.cmd는 godot에 -a를 넘기므로 동일 패턴).
    $probeRoot = Join-Path ([IO.Path]::GetTempPath()) ("smoke_argv_" + [Guid]::NewGuid().ToString("N"))
    # cmd.exe는 경로의 괄호를 subshell로 해석하므로 프로브 파일 경로는 단순하게 둔다.
    # 공백·괄호·끝 백슬래시는 전달 인수(edgeArgs) 쪽에서 검증한다.
    $stressDir = Join-Path $probeRoot "probe"
    New-Item -ItemType Directory -Path $stressDir -Force | Out-Null

    $probePs1 = Join-Path $stressDir "argv_probe.ps1"
    $probePs1Content = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$OutPath,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)
$encoded = @($RemainingArgs | ForEach-Object {
    [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$_))
})
[System.IO.File]::WriteAllLines($OutPath, $encoded, [System.Text.UTF8Encoding]::new($false))
'@
    [System.IO.File]::WriteAllText($probePs1, $probePs1Content, [System.Text.UTF8Encoding]::new($false))

    $probeGdUnitPs1 = Join-Path $stressDir "argv_probe_gdunit.ps1"
    $probeGdUnitContent = @'
param(
    [string[]]$ArgumentList = @()
)
$outPath = $env:SMOKE_ARGV_OUT
if ([string]::IsNullOrWhiteSpace($outPath)) {
    Write-Error "argv_probe_gdunit: SMOKE_ARGV_OUT is not set"
    exit 1
}
$forwardArgs = @($ArgumentList | Where-Object { -not [string]::IsNullOrEmpty($_) })
& (Join-Path $PSScriptRoot "argv_probe.ps1") -OutPath $outPath @forwardArgs
if ($?) { exit 0 }
exit 1
'@
    [System.IO.File]::WriteAllText($probeGdUnitPs1, $probeGdUnitContent, [System.Text.UTF8Encoding]::new($false))

    $probeEdgePs1 = Join-Path $stressDir "argv_probe_edge.ps1"
    $probeEdgeContent = @'
param(
    [string[]]$ArgumentList = @()
)
$outPath = $env:SMOKE_ARGV_OUT
if ([string]::IsNullOrWhiteSpace($outPath)) {
    Write-Error "argv_probe_edge: SMOKE_ARGV_OUT is not set"
    exit 1
}
$forwardArgs = @($ArgumentList | Where-Object { -not [string]::IsNullOrEmpty($_) })
& (Join-Path $PSScriptRoot "argv_probe.ps1") -OutPath $outPath @forwardArgs
if ($?) { exit 0 }
exit 1
'@
    [System.IO.File]::WriteAllText($probeEdgePs1, $probeEdgeContent, [System.Text.UTF8Encoding]::new($false))

    $probeCmd = Join-Path $stressDir "argv_probe.cmd"
    $probeCmdContent = @'
@echo off
powershell -NoProfile -NoLogo -Command "& '%~dp0argv_probe_gdunit.ps1' @('%1','%2','%3','%4','%5','%6','%7','%8')"
exit /b %ERRORLEVEL%
'@

    $probeEdgeCmd = Join-Path $stressDir "argv_probe_edge.cmd"
    $probeEdgeCmdContent = @'
@echo off
powershell -NoProfile -NoLogo -Command "& '%~dp0argv_probe_edge.ps1' @('%1','%2','%3','%4','%5','%6','%7','%8')"
exit /b %ERRORLEVEL%
'@
    [System.IO.File]::WriteAllText($probeCmd, $probeCmdContent, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText($probeEdgeCmd, $probeEdgeCmdContent, [System.Text.UTF8Encoding]::new($false))

    return @{
        ProbeRoot    = $probeRoot
        ProbePs1     = $probePs1
        ProbeCmd     = $probeCmd
        ProbeEdgeCmd = $probeEdgeCmd
    }
}

function Read-SmokeArgvProbeOutput {
    param([string] $OutPath)

    if (-not (Test-Path -LiteralPath $OutPath)) {
        return @()
    }

    $decoded = @()
    foreach ($line in [System.IO.File]::ReadAllLines($OutPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $bytes = [Convert]::FromBase64String($line)
        $decoded += [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    return $decoded
}

function Compare-SmokeArgvLists {
    param(
        [string[]] $Expected,
        [string[]] $Received,
        [string] $Label
    )

    $failures = @()
    if ($Expected.Count -ne $Received.Count) {
        $receivedPreview = ($Received | ForEach-Object { "[$_]" }) -join ","
        $failures += ("{0}: count expected={1} got={2} received={3}" -f $Label, $Expected.Count, $Received.Count, $receivedPreview)
        return $failures
    }

    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($Expected[$index] -ne $Received[$index]) {
            $failures += ("{0}: arg[{1}] expected=[{2}] got=[{3}]" -f $Label, $index, $Expected[$index], $Received[$index])
        }
    }
    return $failures
}

function Test-SmokeArgvRoundTripSelfTest {
    $failures = @()
    $artifacts = New-SmokeSelfTestArtifacts
    $psExe = Join-Path $PSHome "powershell.exe"

    if (-not (Test-Path -LiteralPath $psExe)) {
        return @("argv_roundtrip: powershell.exe not found at $psExe")
    }

    $edgeArgs = @(
        "plain"
        "C:\Program Files (x86)\app\"
        'say "hello"'
    )

    try {
        $directOut = Join-Path $artifacts.ProbeRoot "argv_direct.txt"
        $directArgList = @(
            "-NoProfile", "-NoLogo", "-File", $artifacts.ProbePs1,
            "-OutPath", $directOut
        ) + $edgeArgs

        $directRun = Invoke-NativeProcess `
            -FilePath $psExe `
            -ArgumentList $directArgList `
            -WorkingDirectory $ProjectRoot

        if ($directRun.ExitCode -ne 0) {
            $failures += "argv_roundtrip:direct ps exit=$($directRun.ExitCode)"
        }
        else {
            $failures += Compare-SmokeArgvLists `
                -Expected $edgeArgs `
                -Received (Read-SmokeArgvProbeOutput -OutPath $directOut) `
                -Label "argv_roundtrip:direct"
        }

        $comSpec = Get-SafeEnvPath "ComSpec"
        if (-not $comSpec) {
            $comSpec = Join-Path $env:SystemRoot "System32\cmd.exe"
        }

        $cmdOut = Join-Path $artifacts.ProbeRoot "argv_cmd.txt"
        $cmdPatternArgs = @("-a", "test")
        $cmdRun = Invoke-NativeProcess `
            -FilePath $comSpec `
            -ArgumentList (@("/c", $artifacts.ProbeCmd) + $cmdPatternArgs) `
            -WorkingDirectory $ProjectRoot `
            -Environment @{ SMOKE_ARGV_OUT = $cmdOut }

        if ($cmdRun.ExitCode -ne 0) {
            $failures += "argv_roundtrip:cmd exit=$($cmdRun.ExitCode)"
        }
        else {
            $failures += Compare-SmokeArgvLists `
                -Expected $cmdPatternArgs `
                -Received (Read-SmokeArgvProbeOutput -OutPath $cmdOut) `
                -Label "argv_roundtrip:cmd(gdUnit-like)"
        }

        $cmdEdgeOut = Join-Path $artifacts.ProbeRoot "argv_cmd_edge.txt"
        $cmdEdgeRun = Invoke-NativeProcess `
            -FilePath $comSpec `
            -ArgumentList (@("/c", $artifacts.ProbeEdgeCmd) + $edgeArgs) `
            -WorkingDirectory $ProjectRoot `
            -Environment @{ SMOKE_ARGV_OUT = $cmdEdgeOut }

        if ($cmdEdgeRun.ExitCode -ne 0) {
            $failures += "argv_roundtrip:cmd_edge exit=$($cmdEdgeRun.ExitCode)"
        }
        else {
            $failures += Compare-SmokeArgvLists `
                -Expected $edgeArgs `
                -Received (Read-SmokeArgvProbeOutput -OutPath $cmdEdgeOut) `
                -Label "argv_roundtrip:cmd_edge"
        }
    }
    finally {
        Remove-Item -LiteralPath $artifacts.ProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    return $failures
}

function Test-SmokeNativeProcessLiveProbe {
    $failures = @()
    $psExe = Join-Path $PSHome "powershell.exe"
    if (-not (Test-Path -LiteralPath $psExe)) {
        $failures += "live_probe: powershell.exe not found at $psExe"
        return $failures
    }

    $marker = "smoke_probe_" + [Guid]::NewGuid().ToString("N")
    $run = Invoke-NativeProcess `
        -FilePath $psExe `
        -ArgumentList @("-NoProfile", "-NoLogo", "-Command", 'Write-Output $env:SMOKE_PROBE') `
        -WorkingDirectory $ProjectRoot `
        -Environment @{ SMOKE_PROBE = $marker }

    $outputText = ($run.Output | ForEach-Object { [string]$_ }) -join " "
    if ($run.ExitCode -ne 0) {
        $failures += "live_probe: exit=$($run.ExitCode)"
    }
    if ($outputText -notmatch [regex]::Escape($marker)) {
        $failures += "live_probe: env round-trip failed (output=$outputText)"
    }

    if ($script:NativeProcessModeUsed -ne (Get-NativeProcessModeLabel)) {
        $failures += ("live_probe: mode mismatch used={0} expected={1}" -f `
                $script:NativeProcessModeUsed, (Get-NativeProcessModeLabel))
    }

    return $failures
}

function Invoke-SmokeSelfTest {
    Write-Host ""
    Write-Host "Smoke infrastructure self-test" -ForegroundColor White
    Write-SmokeRuntimeBanner
    Write-Host ("=" * 60) -ForegroundColor DarkGray

    $allFailures = @()
    $allFailures += Test-SmokeQuotingSelfTest
    $allFailures += Test-SmokeArgvRoundTripSelfTest
    $allFailures += Test-SmokeNativeProcessLiveProbe

    if ($allFailures.Count -eq 0) {
        Write-Host "[PASS] self-test (quoting + argv round-trip + live probe)" -ForegroundColor Green
        Write-Host ("  mode_used={0}" -f $script:NativeProcessModeUsed) -ForegroundColor DarkGray
        return $true
    }

    Write-Host "[FAIL] self-test ($($allFailures.Count) issue(s))" -ForegroundColor Red
    foreach ($failure in $allFailures) {
        Write-Host "  $failure" -ForegroundColor DarkRed
    }
    return $false
}

function Test-ProcessArgumentListSupported {
    if ($null -ne $script:ProcessArgumentListSupported) {
        return $script:ProcessArgumentListSupported
    }

    $property = [System.Diagnostics.ProcessStartInfo].GetProperty("ArgumentList")
    $script:ProcessArgumentListSupported = ($null -ne $property)
    return $script:ProcessArgumentListSupported
}

function Get-ProcessEnvSnapshot {
    param([string] $Name)

    $item = Get-Item -Path ("Env:{0}" -f $Name) -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        return @{ IsSet = $false; Value = $null }
    }
    return @{ IsSet = $true; Value = $item.Value }
}

function Restore-ProcessEnvSnapshot {
    param(
        [hashtable] $Snapshot,
        [string] $Name
    )

    if ($Snapshot.IsSet) {
        Set-Item -Path ("Env:{0}" -f $Name) -Value $Snapshot.Value
    }
    else {
        Remove-Item -Path ("Env:{0}" -f $Name) -ErrorAction SilentlyContinue
    }
}

function Start-NativeProcessWithFileRedirect {
    param(
        [string] $FilePath,
        [string[]] $ArgumentList,
        [string] $WorkingDirectory,
        [string] $StdoutPath,
        [string] $StderrPath
    )

    if (Test-ProcessArgumentListSupported) {
        $script:NativeProcessModeUsed = "ArgumentList"
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.WorkingDirectory = $WorkingDirectory
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true

        foreach ($argument in $ArgumentList) {
            [void]$psi.ArgumentList.Add([string]$argument)
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        [void]$process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        [System.IO.File]::WriteAllText($StdoutPath, $stdoutTask.Result, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText($StderrPath, $stderrTask.Result, [System.Text.UTF8Encoding]::new($false))
        return $process
    }

    $script:NativeProcessModeUsed = "EscapedArguments"
    $argString = Join-ProcessArguments -ArgumentList $ArgumentList
    return Start-Process `
        -FilePath $FilePath `
        -ArgumentList $argString `
        -WorkingDirectory $WorkingDirectory `
        -Wait `
        -PassThru `
        -NoNewWindow `
        -RedirectStandardOutput $StdoutPath `
        -RedirectStandardError $StderrPath
}

function Join-ProcessArguments {
    param([string[]] $ArgumentList)

    if ($null -eq $ArgumentList -or $ArgumentList.Count -eq 0) {
        return ""
    }
    return (($ArgumentList | ForEach-Object { Get-EscapedProcessArgument $_ }) -join ' ')
}

function Invoke-NativeProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,
        [string[]] $ArgumentList = @(),
        [string] $WorkingDirectory = $ProjectRoot,
        [hashtable] $Environment = @{}
    )

    $stdoutPath = [IO.Path]::GetTempFileName()
    $stderrPath = [IO.Path]::GetTempFileName()

    try {
        $savedEnv = @{}
        foreach ($key in $Environment.Keys) {
            $savedEnv[$key] = Get-ProcessEnvSnapshot -Name $key
            Set-Item -Path ("Env:{0}" -f $key) -Value ([string]$Environment[$key])
        }

        $process = Start-NativeProcessWithFileRedirect `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -WorkingDirectory $WorkingDirectory `
            -StdoutPath $stdoutPath `
            -StderrPath $stderrPath
    }
    finally {
        foreach ($key in $Environment.Keys) {
            Restore-ProcessEnvSnapshot -Snapshot $savedEnv[$key] -Name $key
        }
    }

    $output = @()
    if (Test-Path -LiteralPath $stdoutPath) {
        $output += Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $stderrPath) {
        $output += Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue
    }

    $stdoutText = ""
    $stderrText = ""
    if (Test-Path -LiteralPath $stdoutPath) {
        $stdoutText = [IO.File]::ReadAllText($stdoutPath)
    }
    if (Test-Path -LiteralPath $stderrPath) {
        $stderrText = [IO.File]::ReadAllText($stderrPath)
    }

    Remove-Item -LiteralPath $stdoutPath, $stderrPath -ErrorAction SilentlyContinue

    return [PSCustomObject]@{
        ExitCode = $process.ExitCode
        Output   = @($output | Where-Object { $_ -ne $null })
        StdOut   = $stdoutText
        StdErr   = $stderrText
    }
}

function Test-GodotVersion {
    param(
        [string] $GodotExe,
        [string] $ExpectedMajorMinor,
        [string] $ExpectedSource
    )

    Write-Host "[....] Godot version (expected $ExpectedMajorMinor.x from $ExpectedSource)" -ForegroundColor Cyan
    $logPath = New-SmokeLogPath -StepName "Godot_version"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $run = Invoke-NativeProcess -FilePath $GodotExe -ArgumentList @("--version") -WorkingDirectory $ProjectRoot
    $stopwatch.Stop()

    Write-LogFile -Path $logPath -Lines @($run.Output)
    $versionLine = @($run.Output | Select-Object -First 1) -join ""
    $passed = $false
    $detail = ""

    if ([string]::IsNullOrWhiteSpace($versionLine)) {
        $detail = "Godot --version returned no output"
    }
    elseif ($versionLine -match '^([0-9]+\.[0-9]+)') {
        $actual = $Matches[1]
        if ($actual -eq $ExpectedMajorMinor) {
            $passed = $true
            $detail = $versionLine
        }
        else {
            $detail = "Mismatch: $versionLine (expected $ExpectedMajorMinor.x from $ExpectedSource)"
        }
    }
    else {
        $detail = "Could not parse version: $versionLine"
    }

    if ($run.ExitCode -gt 0) {
        $passed = $false
        $detail = "exit=$($run.ExitCode); $detail"
    }

    $result = New-SmokeStepResult -Name "Godot version" -Passed $passed -ExitCode $run.ExitCode `
        -DurationMs $stopwatch.ElapsedMilliseconds -LogPath $logPath -Detail $detail
    Write-SmokeStepResult -Result $result
    return $result
}

function Invoke-GodotSmokeCore {
    param(
        [string] $GodotExe,
        [string[]] $Arguments,
        [string] $StepName
    )

    $logPath = New-SmokeLogPath -StepName $StepName
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $run = Invoke-NativeProcess -FilePath $GodotExe -ArgumentList $Arguments -WorkingDirectory $ProjectRoot
    $stopwatch.Stop()

    Write-LogFile -Path $logPath -Lines @($run.Output)

    $criticalMatches = @($run.Output | Select-String -Pattern $GodotCriticalErrorPattern)
    $benignMatches = @($run.Output | Select-String -Pattern $GodotBenignExitNoisePattern)
    $errorLines = $criticalMatches.Count
    $passed = ($run.ExitCode -le 0) -and ($criticalMatches.Count -eq 0)

    $detail = ""
    if (-not $passed) {
        if ($criticalMatches.Count -gt 0) {
            $detail = (@($criticalMatches | Select-Object -First 3 | ForEach-Object { $_.Line }) -join " | ")
        }
        elseif ($run.ExitCode -gt 0) {
            $detail = "Non-zero exit code $($run.ExitCode)"
        }
    }
    elseif ($benignMatches.Count -gt 0) {
        $detail = "benign exit noise ignored: $($benignMatches.Count) line(s)"
    }

    return New-SmokeStepResult -Name $StepName -Passed $passed -ExitCode $run.ExitCode `
        -ErrorLines $errorLines -DurationMs $stopwatch.ElapsedMilliseconds -LogPath $logPath -Detail $detail
}

function Invoke-GodotSmoke {
    param(
        [string] $GodotExe,
        [string[]] $Arguments,
        [string] $StepName
    )

    Write-Host "[....] $StepName" -ForegroundColor Cyan
    $result = Invoke-GodotSmokeCore -GodotExe $GodotExe -Arguments $Arguments -StepName $StepName
    Write-SmokeStepResult -Result $result
    return $result
}

function Invoke-GodotSmokeWithRetry {
    param(
        [string] $GodotExe,
        [string[]] $Arguments,
        [string] $StepName,
        [int] $MaxAttempts
    )

    Write-Host "[....] $StepName" -ForegroundColor Cyan

    $attemptNotes = @()
    $totalDurationMs = 0
    $finalResult = $null

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if ($attempt -gt 1) {
            Write-Host "[RETRY] $StepName (attempt $attempt/$MaxAttempts)" -ForegroundColor DarkYellow
        }

        $attemptResult = Invoke-GodotSmokeCore -GodotExe $GodotExe -Arguments $Arguments -StepName $StepName
        $totalDurationMs += $attemptResult.DurationMs
        $attemptNotes += ("attempt {0}: exit={1} pass={2}" -f $attempt, $attemptResult.ExitCode, $attemptResult.Passed)

        if ($attemptResult.Passed) {
            $detail = $attemptResult.Detail
            if ($attempt -gt 1) {
                $detail = ("recovered on attempt {0}; {1}; {2}" -f $attempt, ($attemptNotes -join "; "), $detail)
            }
            $finalResult = New-SmokeStepResult -Name $StepName -Passed $true -ExitCode $attemptResult.ExitCode `
                -ErrorLines $attemptResult.ErrorLines -DurationMs $totalDurationMs `
                -LogPath $attemptResult.LogPath -Detail $detail
            Write-SmokeStepResult -Result $finalResult
            return $finalResult
        }

        $finalResult = $attemptResult
    }

    $failDetail = ("failed after {0} attempts; {1}" -f $MaxAttempts, ($attemptNotes -join "; "))
    if ($finalResult -and $finalResult.Detail) {
        $failDetail += "; " + $finalResult.Detail
    }

    $finalResult = New-SmokeStepResult -Name $StepName -Passed $false -ExitCode $finalResult.ExitCode `
        -ErrorLines $finalResult.ErrorLines -DurationMs $totalDurationMs `
        -LogPath $finalResult.LogPath -Detail $failDetail
    Write-SmokeStepResult -Result $finalResult
    return $finalResult
}

function Test-ProjectHeadlessLoad {
    param(
        [string] $GodotExe,
        [int] $QuitAfter,
        [int] $MaxAttempts
    )

    return Invoke-GodotSmokeWithRetry -GodotExe $GodotExe -MaxAttempts $MaxAttempts -StepName "Headless project load" -Arguments @(
        "--headless", "--path", ".", "--quit-after", "$QuitAfter"
    )
}

function Test-SceneHeadlessLoads {
    param(
        [string] $GodotExe,
        [int] $QuitAfter,
        [int] $MaxAttempts
    )

    $results = @()
    foreach ($scene in $KeyScenes) {
        $results += Invoke-GodotSmokeWithRetry -GodotExe $GodotExe -MaxAttempts $MaxAttempts `
            -StepName "Headless scene load: $scene" -Arguments @(
                "--headless", "--path", ".", $scene, "--quit-after", "$QuitAfter"
            )
    }
    return $results
}

function Get-SceneFilesForExtResourceCheck {
    if ($FullStaticChecks) {
        return @(Get-ChildItem -LiteralPath $ProjectRoot -Recurse -Filter *.tscn -File |
            Where-Object { $_.FullName -notmatch '[\\/]\.godot[\\/]' } |
            ForEach-Object { $_.FullName.Substring($ProjectRoot.Length).TrimStart('\', '/') })
    }
    return $KeySceneFiles
}

function Test-StaticResources {
    Write-Host "[....] UTF-8 BOM check (.tscn / .tres)" -ForegroundColor Cyan
    $bomStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $bomFiles = @()

    Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File |
        Where-Object {
            ($_.Extension -eq '.tscn' -or $_.Extension -eq '.tres') -and
            ($_.FullName -notmatch '[\\/]\.godot[\\/]') -and
            ($_.FullName -notmatch '[\\/]reports[\\/]smoke_logs[\\/]')
        } |
        ForEach-Object {
            $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                $relative = $_.FullName.Substring($ProjectRoot.Length).TrimStart('\', '/')
                $bomFiles += $relative
            }
        }
    $bomStopwatch.Stop()

    if ($bomFiles.Count -ne 0) {
        $detail = "BOM files: " + (($bomFiles | Select-Object -First 5) -join ", ")
        $bomResult = New-SmokeStepResult -Name "UTF-8 BOM check" -Passed $false `
            -DurationMs $bomStopwatch.ElapsedMilliseconds -Detail $detail
        Write-SmokeStepResult -Result $bomResult
        return @($bomResult)
    }

    $bomResult = New-SmokeStepResult -Name "UTF-8 BOM check" -Passed $true `
        -DurationMs $bomStopwatch.ElapsedMilliseconds -Detail "No BOM in .tscn/.tres"
    Write-SmokeStepResult -Result $bomResult

    $sceneFiles = Get-SceneFilesForExtResourceCheck
    $scopeLabel = if ($FullStaticChecks) { "all .tscn ($($sceneFiles.Count) files)" } else { "key scenes ($($sceneFiles.Count) files)" }
    Write-Host "[....] ext_resource path check ($scopeLabel)" -ForegroundColor Cyan

    $extStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $missingResources = @()
    $resourceChecked = 0

    foreach ($sceneFile in $sceneFiles) {
        $scenePath = Join-Path $ProjectRoot ($sceneFile -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $scenePath)) {
            $missingResources += "MISSING SCENE: $sceneFile"
            continue
        }

        $sceneContent = Get-Content -LiteralPath $scenePath -Raw
        $resourcePaths = [regex]::Matches($sceneContent, $ExtResourcePattern)
        foreach ($resourcePath in $resourcePaths) {
            $resourceChecked++
            $relativePath = $resourcePath.Groups[1].Value.Substring(6).Replace('/', [IO.Path]::DirectorySeparatorChar)
            $targetPath = Join-Path $ProjectRoot $relativePath
            if (-not (Test-Path -LiteralPath $targetPath)) {
                $missingResources += ($sceneFile + ": " + $resourcePath.Groups[1].Value)
            }
        }
    }
    $extStopwatch.Stop()

    if ($missingResources.Count -ne 0) {
        $detail = "Missing " + $missingResources.Count + " of " + $resourceChecked + "; " + (($missingResources | Select-Object -First 3) -join " | ")
        $extResult = New-SmokeStepResult -Name "ext_resource path check" -Passed $false `
            -DurationMs $extStopwatch.ElapsedMilliseconds -Detail $detail
        Write-SmokeStepResult -Result $extResult
        return @($bomResult, $extResult)
    }

    $extResult = New-SmokeStepResult -Name "ext_resource path check" -Passed $true `
        -DurationMs $extStopwatch.ElapsedMilliseconds -Detail "$resourceChecked paths checked ($scopeLabel)"
    Write-SmokeStepResult -Result $extResult
    return @($bomResult, $extResult)
}

function Invoke-UnitTests {
    param([string] $GodotExe)

    Write-Host "[....] gdUnit4 test/" -ForegroundColor Cyan
    $runtest = Join-Path $ProjectRoot "addons\gdUnit4\runtest.cmd"
    if (-not (Test-Path -LiteralPath $runtest)) {
        $result = New-SmokeStepResult -Name "gdUnit4 test/" -Passed $false -Detail "Missing: $runtest"
        Write-SmokeStepResult -Result $result
        return $result
    }

    # gdUnit4 ships runtest.cmd; cmd.exe is one extra parsing layer (see -SelfTest for infra checks).
    # Long-term: invoke GdUnitCmdTool.gd directly if gdUnit adds a PS-friendly entrypoint.
    $logPath = New-SmokeLogPath -StepName "gdUnit4_test"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $comSpec = Get-SafeEnvPath "ComSpec"
    if (-not $comSpec) {
        $comSpec = Join-Path $env:SystemRoot "System32\cmd.exe"
    }

    # cmd /c + 분리 ArgumentList: 배치 경로 quoting 문제 회피
    $run = Invoke-NativeProcess `
        -FilePath $comSpec `
        -ArgumentList @("/c", $runtest, "-a", "test") `
        -WorkingDirectory $ProjectRoot `
        -Environment @{ GODOT_BIN = $GodotExe }

    $stopwatch.Stop()
    Write-LogFile -Path $logPath -Lines @($run.Output)
    $run.Output | ForEach-Object { Write-Host $_ }

    $passed = ($run.ExitCode -eq 0)
    $detail = ""
    if (-not $passed) {
        $detail = "exit=$($run.ExitCode)"
    }

    $result = New-SmokeStepResult -Name "gdUnit4 test/" -Passed $passed -ExitCode $run.ExitCode `
        -DurationMs $stopwatch.ElapsedMilliseconds -LogPath $logPath -Detail $detail
    Write-SmokeStepResult -Result $result
    return $result
}

function Write-SmokeSummary {
    $passedCount = @($script:StepResults | Where-Object { $_.Passed }).Count
    $failedCount = @($script:StepResults | Where-Object { -not $_.Passed }).Count
    $totalMs = ($script:StepResults | Measure-Object -Property DurationMs -Sum).Sum

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host "Summary: steps=$($script:StepResults.Count) pass=$passedCount fail=$failedCount total=${totalMs}ms" -ForegroundColor White

    foreach ($failed in @($script:StepResults | Where-Object { -not $_.Passed })) {
        $line = "  - $($failed.Name) (exit=$($failed.ExitCode), errors=$($failed.ErrorLines))"
        if ($failed.LogPath) { $line += " log=$($failed.LogPath)" }
        Write-Host $line -ForegroundColor DarkRed
    }
}

# --- main ---
if ($SelfTest) {
    if (Invoke-SmokeSelfTest) {
        exit 0
    }
    exit 1
}

$headlessAttempts = if ($RetryOnFailure) { 2 } else { 1 }

Write-Host ""
Write-Host "Smoke test - $ProjectRoot" -ForegroundColor White
Write-Host "quit-after=$QuitAfterFrames full_static=$FullStaticChecks retry=$RetryOnFailure log_dir=$LogDir" -ForegroundColor DarkGray
Write-SmokeRuntimeBanner
Write-Host ("=" * 60) -ForegroundColor DarkGray
Write-Host ""

$godotExe = Resolve-GodotBinary -OverridePath $GodotBinary
Write-Host "Godot: $godotExe" -ForegroundColor DarkGray
Write-Host ""

$expected = Get-ExpectedGodotMajorMinor -GodotExe $godotExe
Test-GodotVersion -GodotExe $godotExe -ExpectedMajorMinor $expected.MajorMinor -ExpectedSource $expected.Source | Out-Null

Test-ProjectHeadlessLoad -GodotExe $godotExe -QuitAfter $QuitAfterFrames -MaxAttempts $headlessAttempts | Out-Null
Test-SceneHeadlessLoads -GodotExe $godotExe -QuitAfter $QuitAfterFrames -MaxAttempts $headlessAttempts | Out-Null

if (-not $SkipStaticChecks) {
    Test-StaticResources | Out-Null
}
else {
    Write-SmokeSkip "Static checks (BOM / ext_resource)"
}

if (-not $SkipUnitTests) {
    Invoke-UnitTests -GodotExe $godotExe | Out-Null
}
else {
    Write-SmokeSkip "gdUnit4 test/"
}

Write-SmokeSummary

$anyFailed = @($script:StepResults | Where-Object { -not $_.Passed }).Count -gt 0
if ($anyFailed) {
    Write-Host "Smoke test FAILED" -ForegroundColor Red
    exit 1
}

Write-Host "Smoke test PASSED" -ForegroundColor Green
exit 0
