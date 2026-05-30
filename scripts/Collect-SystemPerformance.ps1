<#
.SYNOPSIS
    ETL Script für System- und Prozessperformance auf Windows Server 2022.

.DESCRIPTION
    Sammelt Systemdaten, prüft Datenqualität, speichert JSON lokal
    und lädt die Daten per Upsert in MongoDB.
#>

param(
    [int]$TopProcesses = 10,
    [string]$OutputPath = ".\output",
    [string]$LogPath = ".\logs\etl.log",
    [switch]$LoadToMongo,
    [string]$Database = "skt_bigdata",
    [string]$Collection = "system_performance"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Level, [string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDirectory = Split-Path $LogPath

    if (!(Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }

    Add-Content -Path $LogPath -Value "$timestamp;$Level;$Message"
    Write-Host "[$Level] $Message"
}

function Get-SystemSnapshot {
    param([int]$TopProcesses)

    Write-Log "INFO" "Systemdaten werden gesammelt"

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $disk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

    $processes = Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First $TopProcesses |
        ForEach-Object {
            [PSCustomObject]@{
                Name       = $_.ProcessName
                Id         = $_.Id
                CpuSeconds = [math]::Round($_.CPU, 2)
                MemoryMB   = [math]::Round($_.WorkingSet64 / 1MB, 2)
            }
        }

    return [PSCustomObject]@{
        Timestamp = Get-Date
        Computer  = $env:COMPUTERNAME
        OS        = $os.Caption
        CPU       = $cpu.Name
        Memory    = [PSCustomObject]@{
            TotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            FreeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            UsedGB  = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
        }
        Disks = $disk | ForEach-Object {
            [PSCustomObject]@{
                Drive  = $_.DeviceID
                SizeGB = [math]::Round($_.Size / 1GB, 2)
                FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                UsedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
            }
        }
        Processes = $processes
    }
}

function Convert-SystemSnapshot {
    param([Parameter(Mandatory)][object]$Snapshot)

    Write-Log "INFO" "Systemdaten werden transformiert"

    $memoryUsagePercent = [math]::Round(($Snapshot.Memory.UsedGB / $Snapshot.Memory.TotalGB) * 100, 2)

    $diskUsage = $Snapshot.Disks | ForEach-Object {
        [PSCustomObject]@{
            Drive             = $_.Drive
            SizeGB            = $_.SizeGB
            FreeGB            = $_.FreeGB
            UsedGB            = $_.UsedGB
            UsagePercent      = [math]::Round(($_.UsedGB / $_.SizeGB) * 100, 2)
            CriticalFreeSpace = $_.FreeGB -lt 10
        }
    }

    $minuteId = "$($Snapshot.Computer)_$($Snapshot.Timestamp.ToString('yyyyMMdd_HHmm'))"

    return [PSCustomObject]@{
        _id                = $minuteId
        Timestamp          = $Snapshot.Timestamp
        Computer           = $Snapshot.Computer
        OS                 = $Snapshot.OS
        CPU                = $Snapshot.CPU
        Memory             = $Snapshot.Memory
        MemoryUsagePercent = $memoryUsagePercent
        Disks              = $diskUsage
        Processes          = $Snapshot.Processes
    }
}

function Test-SystemSnapshot {
    param([Parameter(Mandatory)][object]$Data)

    Write-Log "INFO" "Datenqualitaet wird geprueft"

    if (-not $Data._id) { throw "_id fehlt" }
    if (-not $Data.Timestamp) { throw "Timestamp fehlt" }
    if (-not $Data.Computer) { throw "Computername fehlt" }
    if (-not $Data.OS) { throw "Betriebssystem fehlt" }
    if ($Data.Memory.TotalGB -le 0) { throw "Ungueltiger RAM-Wert" }
    if ($Data.MemoryUsagePercent -lt 0 -or $Data.MemoryUsagePercent -gt 100) {
        throw "Ungueltige Speicherauslastung"
    }
    if (-not $Data.Processes -or $Data.Processes.Count -eq 0) {
        throw "Keine Prozessdaten vorhanden"
    }

    return $true
}

function Save-SystemSnapshot {
    param(
        [Parameter(Mandatory)][object]$Data,
        [string]$OutputPath
    )

    Write-Log "INFO" "JSON Datei wird erstellt"

    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath | Out-Null
    }

    $fileName = "system_performance_$((Get-Date).ToString('yyyyMMdd_HHmmss')).json"
    $filePath = Join-Path $OutputPath $fileName

    $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8

    Write-Log "INFO" "Datei gespeichert: $filePath"
    return $filePath
}

function Import-ToMongoDB {
    param(
        [Parameter(Mandatory)][object]$Data,
        [string]$Database,
        [string]$Collection
    )

    Write-Log "INFO" "Daten werden per Upsert in MongoDB gespeichert"

    $mongosh = Get-Command mongosh -ErrorAction SilentlyContinue

    if (-not $mongosh) {
        throw "mongosh wurde nicht gefunden."
    }

    $json = $Data | ConvertTo-Json -Depth 20 -Compress
    $escapedJson = $json.Replace('\', '\\').Replace("'", "\'")

    $mongoCommand = @"
use $Database
db.$Collection.updateOne(
  { _id: '$($Data._id)' },
  { `$set: JSON.parse('$escapedJson') },
  { upsert: true }
)
db.$Collection.createIndex({ Timestamp: -1 })
db.$Collection.createIndex({ Computer: 1, Timestamp: -1 })
"@

    $mongoCommand | mongosh --quiet

    Write-Log "INFO" "MongoDB Upsert abgeschlossen"
}

function Show-KPI {
    param([Parameter(Mandatory)][object]$Data)

    Write-Log "INFO" "KPIs werden berechnet"

    $topProcess = $Data.Processes | Sort-Object CpuSeconds -Descending | Select-Object -First 1
    $criticalDisks = $Data.Disks | Where-Object { $_.CriticalFreeSpace -eq $true }
    $avgDiskUsage = [math]::Round(($Data.Disks | Measure-Object UsagePercent -Average).Average, 2)

    Write-Host ""
    Write-Host "KPIs"
    Write-Host "Speicherauslastung: $($Data.MemoryUsagePercent)%"
    Write-Host "Durchschnittliche Laufwerksauslastung: $avgDiskUsage%"
    Write-Host "CPU staerkster Prozess: $($topProcess.Name) mit $($topProcess.CpuSeconds) Sekunden"
    Write-Host "Anzahl kritische Laufwerke: $($criticalDisks.Count)"
    Write-Host ""
}

try {
    Write-Log "INFO" "ETL Prozess gestartet"

    $rawData = Get-SystemSnapshot -TopProcesses $TopProcesses
    $cleanData = Convert-SystemSnapshot -Snapshot $rawData

    Test-SystemSnapshot -Data $cleanData | Out-Null

    Save-SystemSnapshot -Data $cleanData -OutputPath $OutputPath | Out-Null

    if ($LoadToMongo) {
        Import-ToMongoDB -Data $cleanData -Database $Database -Collection $Collection
    }

    Show-KPI -Data $cleanData

    Write-Log "INFO" "ETL Prozess erfolgreich abgeschlossen"
}
catch {
    Write-Log "ERROR" "ETL Prozess abgebrochen: $($_.Exception.Message)"
}
finally {
    Write-Log "INFO" "Script beendet"
}