<# :
@echo off
set "AdrenalessPath=%~f0"
powershell -NoProfile -Command "& ([ScriptBlock]::Create([IO.File]::ReadAllText($env:AdrenalessPath))) %*"
exit /b
#>
param(
    [switch]$Apply,
    [switch]$Restore,
    [switch]$Clear,
    [switch]$Open,
    [switch]$Status
)

$ErrorActionPreference = 'Stop'
$Version = '1.4'

# This File, Set By The Batch Header
$ScriptPath = $env:AdrenalessPath

# Original Values Are Kept Until Restore
$BackupPath = Join-Path $env:APPDATA 'Adrenaless\backup.json'
$LegacyBackupPath = Join-Path $env:APPDATA 'Adrenalize\backup.json'

# Adrenalin Settings And The State Each One Is Set To
$Settings = @(
    # Off Makes Adrenalin Crash When Opened During A Game
    @{ Key = 'HKCU:\Software\AMD\DVR'; Name = 'ShowRSOverlay'; Value = 'true'; State = 'On'; Label = 'In Game Overlay' }
    @{ Key = 'HKCU:\Software\AMD\DVR'; Name = 'HotkeysDisabled'; Value = 1; State = 'Off'; Label = 'Hotkeys' }
    @{ Key = 'HKCU:\Software\AMD\CN\Performance'; Name = 'EnableMetricsOverlay'; Value = 0; State = 'Off'; Label = 'Metrics Overlay' }
)

# Adrenalin Itself
$AdrenalinPath = 'C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe'

# Adrenalin's Parts, Background Ones Run Elevated
$AdrenalinProcessNames = @('RadeonSoftware', 'AMDRSServ', 'amdow', 'AMDRSSrcExt', 'CPUMetricsServer', 'cncmd')

# AMD Logon Task That Starts The Recording Server, Adrenalin Itself Stays So Tuning Applies
$TaskNames = @('StartDVR')

function Write-Line([string]$Text = '', [ConsoleColor]$Color = 'Gray') {
    Write-Host $Text -ForegroundColor $Color
}

function Write-State([string]$Label, [string]$State, [bool]$IsSet) {
    $text = if ($IsSet) { $State } elseif ($State -eq 'On') { 'Off' } else { 'On' }
    $color = if ($IsSet) { 'Green' } else { 'Yellow' }
    Write-Line ('  {0,-20}{1}' -f $Label, $text) $color
}

function Get-RegistryValue([string]$Key, [string]$Name) {
    $item = Get-Item -Path $Key -ErrorAction SilentlyContinue
    if (-not $item -or $item.GetValueNames() -notcontains $Name) {
        return $null
    }

    @{ Value = $item.GetValue($Name); Kind = $item.GetValueKind($Name).ToString() }
}

function Set-RegistryValue([string]$Key, [string]$Name, $Value, [string]$Kind) {
    if (-not (Test-Path $Key)) {
        New-Item -Path $Key -Force | Out-Null
    }

    # Adrenalin Ignores A Value Of The Wrong Type
    if (-not $Kind) {
        $Kind = if ($Value -is [string]) { 'String' } else { 'DWord' }
    }

    New-ItemProperty -Path $Key -Name $Name -Value $Value -PropertyType $Kind -Force | Out-Null
}

function Get-TaskState([string]$Name) {
    $task = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
    if ($task) { $task.State.ToString() } else { 'Missing' }
}

function Show-Status {
    Write-Line
    Write-Line "Adrenaless v$Version" Cyan
    Write-Line

    foreach ($setting in $Settings) {
        $current = Get-RegistryValue $setting.Key $setting.Name
        Write-State $setting.Label $setting.State ($current -and "$($current.Value)" -eq "$($setting.Value)")
    }

    foreach ($name in $TaskNames) {
        Write-State "Task $name" 'Off' ((Get-TaskState $name) -in 'Disabled', 'Missing')
    }

    Write-Line
}

function Invoke-Elevated([string]$Argument) {
    # AMD's Tasks And Background Parts Need Administrator Rights
    try {
        Start-Process -FilePath $ScriptPath -ArgumentList $Argument -Verb RunAs -Wait -WindowStyle Hidden
        $true
    }
    catch {
        Write-Line 'Administrator Rights Were Declined' Red
        $false
    }
}

function Save-Backup {
    # Only The First Run Records Originals, A Rerun Would Save Values Already Changed
    if (Test-Path $BackupPath) {
        return
    }

    $backup = @{
        Settings = @($Settings | ForEach-Object {
            $current = Get-RegistryValue $_.Key $_.Name
            @{ Key = $_.Key; Name = $_.Name; Existed = [bool]$current; Value = $current.Value; Kind = $current.Kind }
        })
        Tasks = @($TaskNames | ForEach-Object { @{ Name = $_; State = Get-TaskState $_ } })
    }

    New-Item -ItemType Directory -Path (Split-Path $BackupPath) -Force | Out-Null
    $backup | ConvertTo-Json -Depth 4 | Set-Content -Path $BackupPath -Encoding UTF8
}

function Set-AdrenalinSettings {
    Save-Backup

    foreach ($setting in $Settings) {
        $current = Get-RegistryValue $setting.Key $setting.Name
        Set-RegistryValue $setting.Key $setting.Name $setting.Value $current.Kind
    }

    foreach ($name in $TaskNames) {
        if ((Get-TaskState $name) -notin 'Disabled', 'Missing') {
            Disable-ScheduledTask -TaskName $name | Out-Null
        }
    }
}

function Restore-AdrenalinSettings {
    $backup = Get-Content -Path $BackupPath -Raw | ConvertFrom-Json

    foreach ($saved in $backup.Settings) {
        if ($saved.Existed) {
            Set-RegistryValue $saved.Key $saved.Name $saved.Value $saved.Kind
        }
        elseif (Test-Path $saved.Key) {
            Remove-ItemProperty -Path $saved.Key -Name $saved.Name -ErrorAction SilentlyContinue
        }
    }

    foreach ($saved in $backup.Tasks) {
        if ($saved.State -notin 'Disabled', 'Missing') {
            Enable-ScheduledTask -TaskName $saved.Name | Out-Null
        }
    }

    Remove-Item -Path $BackupPath -Force
}

function Test-AdrenalinWindow {
    # A Copy Without A Visible Window Is Stuck, Not Open
    [bool](Get-Process -Name RadeonSoftware -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like 'AMD Software*' })
}

function Wait-AdrenalinWindow([int]$Seconds) {
    for ($second = 0; $second -lt $Seconds; $second++) {
        if (Test-AdrenalinWindow) {
            return $true
        }
        Start-Sleep -Seconds 1
    }

    $false
}

function Open-Adrenalin {
    # Adrenalin Quits During Startup When Launched Elevated, So This Runs As The User
    Start-Process -FilePath $AdrenalinPath
    if (Wait-AdrenalinWindow 12) {
        Write-Line 'Adrenalin Opened' Green
        return
    }

    # Stale Background Parts Swallow Every Launch
    Write-Line 'Adrenalin Is Stuck, Clearing It' Yellow
    if (-not (Invoke-Elevated '-Clear')) {
        return
    }

    Start-Process -FilePath $AdrenalinPath
    if (Wait-AdrenalinWindow 30) {
        Write-Line 'Adrenalin Opened' Green
    }
    else {
        Write-Line 'Adrenalin Did Not Open' Red
    }
}

# Adrenalize 3 Kept Its Backup Under Its Own Name
if (-not (Test-Path $BackupPath) -and (Test-Path $LegacyBackupPath)) {
    New-Item -ItemType Directory -Path (Split-Path $BackupPath) -Force | Out-Null
    Move-Item -Path $LegacyBackupPath -Destination $BackupPath
}

# Elevated Steps, Started By The Menu
if ($Apply) {
    Set-AdrenalinSettings
    return
}

if ($Restore) {
    Restore-AdrenalinSettings
    return
}

if ($Clear) {
    Get-Process -Name $AdrenalinProcessNames -ErrorAction SilentlyContinue | Stop-Process -Force
    return
}

if ($Status) {
    Show-Status
    return
}

if ($Open) {
    Open-Adrenalin
    return
}

Show-Status
Write-Line '  1  Apply Settings' White
Write-Line '  2  Restore Everything' White
Write-Line '  3  Open Adrenalin' White
Write-Line '  Q  Quit' White
Write-Line

switch ((Read-Host 'Choose').Trim()) {
    '1' {
        if (-not (Invoke-Elevated '-Apply')) {
            return
        }
    }
    '2' {
        if (-not (Test-Path $BackupPath)) {
            Write-Line 'Nothing To Restore' Yellow
            return
        }
        if (-not (Invoke-Elevated '-Restore')) {
            return
        }
    }
    '3' {
        Open-Adrenalin
        return
    }
    default {
        return
    }
}

Show-Status

if ((Read-Host 'Restart Now To Finish, Y Or N').Trim() -eq 'Y') {
    Restart-Computer
}
