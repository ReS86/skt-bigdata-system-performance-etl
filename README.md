# System Performance ETL Pipeline mit PowerShell und MongoDB
 
## Projektbeschreibung
 
Dieses Projekt sammelt System- und Prozessleistungsdaten eines Windows Server 2022 Systems mittels PowerShell.
 
Die Daten werden durch eine ETL-Pipeline verarbeitet, als JSON archiviert und mittels Upsert in MongoDB gespeichert.
 
Zusätzlich werden KPIs berechnet und verschiedene MongoDB-Aggregationen zur Analyse bereitgestellt.
 
---
 
## Architektur
 
Windows Server 2022
    ↓
PowerShell ETL
    ↓
Extract
    ↓
Transform
    ↓
Data Quality Check
    ↓
JSON Export
    ↓
MongoDB Upsert
    ↓
KPI Analyse
 
---
 
## Voraussetzungen
 
- Windows Server 2022
- PowerShell 5.1 oder höher
- MongoDB Community Server
- MongoDB Shell (mongosh)
- MongoDB Compass
- MongoDB Database Tools
 
---
 
## Installation
 
### MongoDB
 
MongoDB Community Server installieren.
 
### MongoDB Shell
 
mongosh installieren.
 
### MongoDB Database Tools
 
mongoimport installieren.
 
---
 
## Ausführung
 
```powershell
.\Collect-SystemPerformance.ps1
```
 
Mit MongoDB:
 
```powershell
.\Collect-SystemPerformance.ps1 -LoadToMongo
```
 
---
 
## MongoDB
 
Datenbank:
 
```text
skt_bigdata
```
 
Collection:
 
```text
system_performance
```
 
---
 
## KPI
 
- Speicherauslastung
- Durchschnittliche Laufwerksauslastung
- CPU-stärkster Prozess
- Anzahl kritischer Laufwerke
 
---
 
## Logging
 
```text
logs\etl.log
```
 
Format:
 
```text
Timestamp;Level;Message
```
 
---
 
## Datenqualität
 
- Pflichtfelder vorhanden
- RAM-Werte gültig
- Prozessdaten vorhanden
- Wertebereich geprüft
 
---
 
## Upsert
 
Dokumente werden anhand von:
 
```text
Computername + Zeitstempel
```
 
eindeutig identifiziert.