# Technische Dokumentation

## Komponenten

### PowerShell

Verantwortlich für:

- Datenerfassung
- Transformation
- Datenqualitätsprüfung
- KPI-Berechnung
- Logging

### MongoDB

Persistente Speicherung der Leistungsdaten.

### MongoDB Compass

Grafische Auswertung der Datenbank.

### Windows Task Scheduler

Automatisierte Ausführung der ETL-Pipeline.

---

## Datenmodell

Collection:

system_performance

Beispiel:

```json
{
  "_id": "SRV-SQL01_20260530_1030",
  "Timestamp": "2026-05-30T10:30:00",
  "Computer": "SRV-SQL01",
  "MemoryUsagePercent": 32.5
}
```

---

## MongoDB Indexe

```javascript
db.system_performance.createIndex({ Timestamp: -1 })

db.system_performance.createIndex({
    Computer: 1,
    Timestamp: -1
})
```

---

## Aggregationen

1. Durchschnittliche RAM-Auslastung

2. Letzte Messungen

3. Kritische Laufwerke

---

## Scheduler

Ausführung alle 5 Minuten.

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Administrator\Collect-SystemPerformance.ps1" -LoadToMongo
```