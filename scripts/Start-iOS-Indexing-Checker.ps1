<# 
.SYNOPSIS
One-click launcher for the Windows iOS indexing checker.

.DESCRIPTION
This launcher keeps setup local to this folder:
- verifies the Apple Mobile Device service
- finds Python or offers to install it with winget
- creates .ios-indexing-runtime\venv
- installs pymobiledevice3 into that local runtime
- starts ios-indexing-progress-windows.ps1
#>

[CmdletBinding()]
param(
    [int]$DurationSeconds = 300,
    [string]$DeviceId,
    [switch]$Raw,
    [switch]$AllowPythonFallback,
    [switch]$NoPrompt
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
try {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [Console]::OutputEncoding = $utf8
    $OutputEncoding = $utf8
}
catch {
    # Console encoding is best-effort only.
}

$script:Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RuntimeRoot = Join-Path $script:Root ".ios-indexing-runtime"
$script:VenvPath = Join-Path $script:RuntimeRoot "venv"
$script:VenvPython = Join-Path $script:VenvPath "Scripts\python.exe"
$script:CheckerScript = Join-Path $script:Root "ios-indexing-progress-windows.ps1"
$script:BundledExe = Join-Path $script:Root "IosIndexingProgress.exe"
$script:LogPath = Join-Path $script:Root "ios-indexing-checker.log"

function Write-Log {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $script:LogPath -Encoding UTF8 -Value $line
}

function Write-Step {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
    Write-Log $Message
}

function Wait-User {
    param([string]$Message = "按 Enter 继续")
    [void](Read-Host $Message)
}

function Test-PythonVersion {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @()
    )

    $probe = @"
import sys
major, minor = sys.version_info[:2]
print(f"{major}.{minor}")
sys.exit(0 if (major, minor) >= (3, 9) else 1)
"@

    try {
        $output = & $Command @Arguments -c $probe 2>$null
        if ($LASTEXITCODE -eq 0) {
            return [pscustomobject]@{
                Command = $Command
                Arguments = $Arguments
                Version = [string]$output
            }
        }
    }
    catch {
        return $null
    }

    return $null
}

function Find-Python {
    $candidates = @(
        @{ Command = "py"; Args = @("-3") },
        @{ Command = "python"; Args = @() },
        @{ Command = "python3"; Args = @() }
    )

    foreach ($candidate in $candidates) {
        $found = Get-Command $candidate.Command -ErrorAction SilentlyContinue
        if ($null -eq $found) {
            continue
        }

        $result = Test-PythonVersion -Command $candidate.Command -Arguments $candidate.Args
        if ($null -ne $result) {
            return $result
        }
    }

    return $null
}

function Install-PythonWithWinget {
    $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
    if ($null -eq $winget) {
        throw "没有找到 Python 3.9+，也没有找到 winget。请先安装 Python 3.9 或更新版本，然后重新打开本工具。"
    }

    Write-Step "没有找到可用的 Python。接下来会用 winget 安装 Python 3.12。"
    Write-Host "这个步骤需要联网，Windows 可能会弹出安装确认。"
    Wait-User

    & $winget.Source install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "Python 安装没有成功。请安装 Python 3.9+ 后再运行本工具。"
    }
}

function Ensure-AppleMobileDevice {
    Write-Step "正在检查 Apple Mobile Device Service..."
    $service = Get-Service -Name "Apple Mobile Device Service" -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Step "没有检测到 Apple Mobile Device Service。"
        Write-Host "这通常表示还没安装 Apple Devices 或 iTunes 的 Windows 驱动。"
        Write-Host "请先安装 Apple Devices 或 iTunes，让 Windows 能识别 iPhone，然后重新运行这个工具。"
        exit 10
    }

    if ($service.Status -ne "Running") {
        Write-Step "正在启动 Apple Mobile Device Service..."
        Start-Service -Name "Apple Mobile Device Service"
        Start-Sleep -Seconds 2
    }

    Write-Step "Apple Mobile Device Service 正在运行。"
}

function Test-Pymobiledevice3 {
    param([Parameter(Mandatory = $true)][string]$PythonExe)

    & $PythonExe -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('pymobiledevice3') else 1)" *> $null
    return ($LASTEXITCODE -eq 0)
}

function Ensure-Runtime {
    if (Test-Path -LiteralPath $script:VenvPython) {
        if (Test-Pymobiledevice3 -PythonExe $script:VenvPython) {
            return
        }
    }

    $hostPython = Find-Python
    if ($null -eq $hostPython) {
        Install-PythonWithWinget
        $hostPython = Find-Python
    }

    if ($null -eq $hostPython) {
        throw "仍然没有找到 Python 3.9+。请重新打开 PowerShell，或重启 Windows 后再试。"
    }

    if (-not (Test-Path -LiteralPath $script:RuntimeRoot)) {
        New-Item -ItemType Directory -Force -Path $script:RuntimeRoot | Out-Null
    }

    if (-not (Test-Path -LiteralPath $script:VenvPython)) {
        Write-Step ("正在创建本地运行环境 Python {0}..." -f $hostPython.Version)
        & $hostPython.Command @($hostPython.Arguments + @("-m", "venv", $script:VenvPath))
        if ($LASTEXITCODE -ne 0) {
            throw "创建本地运行环境失败。"
        }
    }

    Write-Step "正在安装 iPhone 日志读取组件 pymobiledevice3..."
    $wheels = Join-Path $script:Root "wheels"
    if (Test-Path -LiteralPath $wheels) {
        & $script:VenvPython -m pip install --no-index --find-links $wheels -U pymobiledevice3
    }
    else {
        & $script:VenvPython -m pip install -U pymobiledevice3
    }

    if ($LASTEXITCODE -ne 0) {
        throw "pymobiledevice3 安装失败。请检查网络，或把离线 wheels 放到本目录的 wheels 文件夹后再试。"
    }
}

function Start-Checker {
    if (Test-Path -LiteralPath $script:BundledExe) {
        Write-Step "正在启动离线核心程序..."
        Write-Host "第一次运行可能需要 10-30 秒解压运行时；这期间请不要关闭窗口。"

        $exeArgs = @("--duration", $DurationSeconds)
        if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
            $exeArgs += @("--udid", $DeviceId)
        }
        if ($Raw) {
            $exeArgs += "--raw"
        }

        Write-Log ("Core command: {0} {1}" -f $script:BundledExe, ($exeArgs -join " "))
        $job = Start-Job -ScriptBlock {
            param($Executable, $Arguments, $Root)
            Set-Location -LiteralPath $Root
            $runtimeTmp = Join-Path $Root "runtime-tmp"
            New-Item -ItemType Directory -Force -Path $runtimeTmp | Out-Null
            $env:TEMP = $runtimeTmp
            $env:TMP = $runtimeTmp
            & $Executable @Arguments 2>&1
            [pscustomobject]@{ __IosIndexingCheckerExitCode = $LASTEXITCODE }
        } -ArgumentList $script:BundledExe, $exeArgs, $script:Root

        $started = Get-Date
        $lastOutput = Get-Date
        $lastHeartbeat = Get-Date
        $exitCode = $null

        try {
            while ($job.State -eq "Running") {
                $items = Receive-Job -Job $job
                foreach ($item in $items) {
                    if ($item.PSObject.Properties.Name -contains "__IosIndexingCheckerExitCode") {
                        $exitCode = [int]$item.__IosIndexingCheckerExitCode
                        continue
                    }
                    $text = [string]$item
                    if (-not [string]::IsNullOrWhiteSpace($text)) {
                        Write-Host $text
                        Write-Log $text
                        $lastOutput = Get-Date
                    }
                }

                $now = Get-Date
                if (($now - $lastHeartbeat).TotalSeconds -ge 5) {
                    $elapsed = [int](($now - $started).TotalSeconds)
                    $silent = [int](($now - $lastOutput).TotalSeconds)
                    Write-Host ("核心程序仍在运行：已等待 {0} 秒，距上次输出 {1} 秒。" -f $elapsed, $silent) -ForegroundColor DarkGray
                    Write-Log ("Heartbeat: elapsed={0}s silent={1}s" -f $elapsed, $silent)
                    $lastHeartbeat = $now
                }

                Start-Sleep -Milliseconds 500
            }

            $items = Receive-Job -Job $job
            foreach ($item in $items) {
                if ($item.PSObject.Properties.Name -contains "__IosIndexingCheckerExitCode") {
                    $exitCode = [int]$item.__IosIndexingCheckerExitCode
                    continue
                }
                $text = [string]$item
                if (-not [string]::IsNullOrWhiteSpace($text)) {
                    Write-Host $text
                    Write-Log $text
                }
            }
        }
        finally {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }

        if ($null -eq $exitCode) {
            Write-Log "Core exited without an exit-code marker."
            return 99
        }

        Write-Log ("Core exit code: {0}" -f $exitCode)
        return $exitCode
    }

    if (-not (Test-Path -LiteralPath $script:CheckerScript)) {
        throw "找不到核心脚本：$script:CheckerScript"
    }

    $args = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $script:CheckerScript,
        "-Backend", "pymobiledevice3",
        "-Python", $script:VenvPython,
        "-DurationSeconds", $DurationSeconds
    )

    if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
        $args += @("-DeviceId", $DeviceId)
    }

    if ($Raw) {
        $args += "-Raw"
    }

    & powershell.exe @args
    return $LASTEXITCODE
}

Clear-Host
Write-Log "PowerShell launcher started."
Write-Host "iOS Indexing Checker for Windows" -ForegroundColor Green
Write-Host ""
Write-Host ("日志文件：{0}" -f $script:LogPath) -ForegroundColor DarkGray
Write-Host ""
Write-Host "准备好之后："
Write-Host "1. 用 USB 插上 iPhone"
Write-Host "2. 解锁 iPhone，并点“信任此电脑”"
Write-Host "3. 在 iPhone 上打开“设置”"
Write-Host ""
if (-not $NoPrompt) {
    Wait-User "准备好后按 Enter 开始"
}

try {
    Ensure-AppleMobileDevice
    if (-not (Test-Path -LiteralPath $script:BundledExe)) {
        if (-not $AllowPythonFallback) {
            throw "这个离线包不完整：缺少 IosIndexingProgress.exe。请重新解压完整 zip。"
        }
        Write-Step "没有找到免安装核心程序，转入维护者备用运行环境准备流程。"
        Ensure-Runtime
    }
    $code = Start-Checker

    Write-Host ""
    if ($code -eq 0) {
        Write-Host "完成：已经读到 iOS 索引进度。" -ForegroundColor Green
    }
    elseif ($code -eq 3) {
        Write-Host "这次没有读到索引进度日志。保持 iPhone 解锁并打开“设置”，可以再运行一次。" -ForegroundColor Yellow
    }
    else {
        Write-Host ("工具结束，退出码：{0}" -f $code) -ForegroundColor Yellow
    }
}
catch {
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
if (-not $NoPrompt) {
    Wait-User "按 Enter 关闭"
}
