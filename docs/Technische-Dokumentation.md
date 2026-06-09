# Technische Dokumentation

## Projektübersicht

Die entwickelte Applikation dient zur automatisierten Erfassung, Verarbeitung und Speicherung von Leistungsdaten eines Windows Server 2022 Systems.

Mittels PowerShell werden Systeminformationen gesammelt, analysiert und über eine ETL-Pipeline verarbeitet. Die Daten werden als JSON-Dateien archiviert und mittels Upsert in einer MongoDB-Datenbank gespeichert. Zusätzlich werden Kennzahlen (KPIs) berechnet und verschiedene MongoDB-Aggregationen zur Analyse bereitgestellt.

---

# Komponenten

## PowerShell ETL-Skript

Das PowerShell-Skript übernimmt die gesamte Datenverarbeitung.

Aufgaben:

- Datenerfassung (Extract)
- Datenaufbereitung (Transform)
- Datenqualitätsprüfung
- Speicherung als JSON-Datei
- Speicherung in MongoDB
- KPI-Berechnung
- Logging
- Fehlerbehandlung

Verwendete Hauptfunktionen:

```powershell
Get-SystemSnapshot
Convert-SystemSnapshot
Test-SystemSnapshot
Save-SystemSnapshot
Import-ToMongoDB
Show-KPI
Write-Log
```

---

## MongoDB

MongoDB dient als persistente Datenbank zur langfristigen Speicherung der Leistungsdaten.

Verwendete Datenbank:

```text
skt_bigdata
```

Verwendete Collection:

```text
system_performance
```

---

## MongoDB Compass

MongoDB Compass wird zur grafischen Darstellung und Analyse der gespeicherten Daten verwendet.

Mögliche Funktionen:

- Dokumente anzeigen
- Filter anwenden
- Aggregationen testen
- Datenmodell analysieren
- Indexe anzeigen

---

## Windows Task Scheduler

Der Windows Task Scheduler ermöglicht die automatische Ausführung der ETL-Pipeline.

Taskname:

```text
System_Performance_Run
```

Intervall:

```text
Alle 5 Minuten
```

---

# ETL-Prozess

## Extract

Die Datenerfassung erfolgt direkt über Windows-Systemschnittstellen.

Verwendete Befehle:

```powershell
Get-CimInstance Win32_OperatingSystem
Get-CimInstance Win32_Processor
Get-CimInstance Win32_LogicalDisk
Get-Process
```

Erfasste Daten:

- Betriebssystem
- CPU
- Arbeitsspeicher
- Laufwerke
- Prozesse

---

## Transform

Während der Transformation werden zusätzliche Informationen berechnet.

Berechnungen:

- Speicherauslastung (%)
- Laufwerksauslastung (%)
- Kritische Laufwerke
- KPI-Werte

Beispiel:

```powershell
MemoryUsagePercent = (UsedMemory / TotalMemory) * 100
```

---

## Load

Die verarbeiteten Daten werden:

1. Als JSON-Datei gespeichert
2. In MongoDB gespeichert

Die Speicherung erfolgt mittels Upsert.

Beispiel:

```javascript
db.system_performance.updateOne(
{
_id: "SERVER01_20260602_1400"
},
{
$set: document
},
{
upsert: true
}
)
```

Dadurch werden Duplikate vermieden.

---

# Datenmodell

Beispieldokument:

```json
{
  "_id": "SRV-SQL01_20260602_1535",
  "Timestamp": "2026-06-02T15:35:00",
  "Computer": "SRV-SQL01",
  "OS": "Microsoft Windows Server 2022 Standard",
  "CPU": "Intel(R) Core(TM) Ultra 9 285H",
  "MemoryUsagePercent": 70.83
}
```

---

# Datenqualitätsprüfung

Vor dem Speichern werden folgende Prüfungen durchgeführt:

- _id vorhanden
- Timestamp vorhanden
- Computername vorhanden
- Betriebssystem vorhanden
- Arbeitsspeicherwerte gültig
- Speicherauslastung zwischen 0 und 100 %
- Prozessdaten vorhanden

Fehlerhafte Datensätze werden nicht gespeichert.

---

# Logging

Alle wichtigen Verarbeitungsschritte werden protokolliert.

Logdatei:

```text
C:\Users\Administrator\skt-bigdata-system-performance-etl\logs\etl.log
```

Format:

```text
Timestamp;Level;Message
```

Beispiel:

```text
2026-06-02 15:30:00;INFO;ETL Prozess gestartet
2026-06-02 15:30:01;INFO;Systemdaten werden gesammelt
2026-06-02 15:30:02;INFO;MongoDB Upsert abgeschlossen
```

---

# Fehlerbehandlung

Die Anwendung verwendet strukturierte Fehlerbehandlung mittels:

```powershell
try
catch
finally
```

Kritische Bereiche:

- Datenerfassung
- JSON-Erstellung
- MongoDB-Verbindung
- KPI-Berechnung

Fehler werden automatisch im Logfile dokumentiert.

---

# MongoDB Indexe

Zur Optimierung der Datenbankabfragen werden folgende Indexe verwendet:

## Zeitstempelindex

```javascript
db.system_performance.createIndex({
Timestamp: -1
})
```

## Computer- und Zeitstempelindex

```javascript
db.system_performance.createIndex({
Computer: 1,
Timestamp: -1
})
```

Vorteile:

- Schnellere Sortierung
- Schnellere Filterung
- Bessere Performance bei grossen Datenmengen

---

# MongoDB Aggregationen

## Aggregation 1 – Durchschnittliche RAM-Auslastung

```javascript
db.system_performance.aggregate([
{
$group:
{
_id: "$Computer",
avgMemoryUsage:
{
$avg: "$MemoryUsagePercent"
}
}
}
])
```

Zweck:

Berechnung der durchschnittlichen Speicherauslastung pro System.

---

## Aggregation 2 – Letzte 3 Messungen

```javascript
db.system_performance.find()
.sort({ Timestamp: -1 })
.limit(3)
```

Zweck:

Anzeige der neuesten Messwerte.

---

## Aggregation 3 – Kritische Laufwerke

```javascript
db.system_performance.aggregate([
{ $unwind: "$Disks" },
{ $match: { "Disks.CriticalFreeSpace": true } },
{
$group:
{
_id: "$Computer",
criticalDisks:
{
$sum: 1
}
}
}
])
```

Zweck:

Ermittlung kritischer Laufwerke mit wenig freiem Speicherplatz.

---

# KPI-Auswertung

Folgende Kennzahlen werden automatisch berechnet:

## KPI 1 – Speicherauslastung

Beispiel:

```text
70.83 %
```

## KPI 2 – Durchschnittliche Laufwerksauslastung

Beispiel:

```text
56.65 %
```

## KPI 3 – CPU-stärkster Prozess

Beispiel:

```text
TiWorker
```

## KPI 4 – Anzahl kritischer Laufwerke

Beispiel:

```text
0
```

---

# Automatisierung

Die ETL-Pipeline wird automatisch über den Windows Task Scheduler gestartet.

Beispiel:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Administrator\skt-bigdata-system-performance-etl\scripts\Collect-SystemPerformance.ps1" -TopProcesses 10 -LoadToMongo
```

Intervall:

```text
Alle 5 Minuten
```

Script:
C:\Users\Administrator\skt-bigdata-system-performance-etl\scripts\Collect-SystemPerformance.ps1

Arbeitsverzeichnis:
C:\Users\Administrator\skt-bigdata-system-performance-etl

Ausgabe:
C:\Users\Administrator\skt-bigdata-system-performance-etl\output

Logdatei:
C:\Users\Administrator\skt-bigdata-system-performance-etl\logs\etl.log

---

# Bekannte Einschränkungen

- Aktuell wird nur ein einzelner Server überwacht.
- Es erfolgt keine automatische Alarmierung.
- Es existiert kein grafisches Dashboard.
- Die Lösung verwendet eine lokale MongoDB-Instanz.
- Mehrserver-Monitoring ist aktuell nicht implementiert.

---

# Fazit

Die entwickelte Lösung implementiert eine vollständige ETL-Pipeline auf Basis von PowerShell und MongoDB. Systemleistungsdaten werden automatisiert erfasst, geprüft, gespeichert und analysiert.

Die Anforderungen der Projektarbeit bezüglich Skripting, ETL, MongoDB, Datenqualität, Logging, Fehlerbehandlung, KPI-Berechnung, Automatisierung und Datenanalyse werden vollständig erfüllt.