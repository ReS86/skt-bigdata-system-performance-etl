# Konzeptdokumentation – Projektarbeit Skriptingtechnik / Big Data

## System Performance ETL Pipeline mit PowerShell und MongoDB

**Modul:** Skriptingtechnik / Big Data  
**Projektteam:** [René Scherer, Mark Zgraggen, Kevin Sacapaño]  
**Datum:** [09.06.2026]  
**Version:** 1.0

---

# 1. Ausgangslage

In modernen IT-Umgebungen ist die kontinuierliche Überwachung von Servern und Systemen ein wichtiger Bestandteil des Betriebs. Administratoren müssen Informationen über Speicherauslastung, Festplattenkapazität, laufende Prozesse und Systemzustände erfassen, um Engpässe frühzeitig zu erkennen und die Systemstabilität sicherzustellen.

Die manuelle Erfassung solcher Daten ist zeitaufwändig und fehleranfällig. Zudem fehlen oft historische Daten, um Entwicklungen über längere Zeiträume zu analysieren.

Im Rahmen dieser Projektarbeit soll deshalb eine automatisierte ETL-Pipeline entwickelt werden, welche Leistungsdaten eines Windows Servers sammelt, verarbeitet und langfristig in einer MongoDB-Datenbank speichert. Die Daten können anschliessend ausgewertet und für Analysen verwendet werden.

Die Lösung kombiniert die beiden Themengebiete Skriptingtechnik und Big Data in einer gemeinsamen Anwendung.

---

# 2. Zielsetzung

## 2.1 Muss-Ziele

| Ziel | Beschreibung |
|--------|-------------|
| PowerShell-Skript | Entwicklung einer ETL-Pipeline mit PowerShell |
| Datenerfassung | Automatische Sammlung von System- und Prozessdaten |
| Transformation | Berechnung und Anreicherung der Rohdaten |
| MongoDB | Speicherung der Daten in MongoDB |
| Logging | Vollständige Protokollierung aller Verarbeitungsschritte |
| Fehlerbehandlung | Verwendung von try/catch/finally |
| Datenqualität | Prüfung der Daten vor dem Speichern |
| Upsert-Logik | Vermeidung von Duplikaten |
| KPI-Berechnung | Berechnung relevanter Kennzahlen |
| Automatisierung | Ausführung über Windows Task Scheduler |
| Dokumentation | Vollständige technische Dokumentation |

---

## 2.2 Wunsch-Ziele

| Ziel | Beschreibung |
|--------|-------------|
| MongoDB Compass | Grafische Analyse der Daten |
| Historische Auswertungen | Langfristige Trendanalysen |
| Erweiterte KPI-Auswertung | Zusätzliche Kennzahlen |
| Dashboard | Spätere Visualisierung der Daten |
| Mehrere Server | Erweiterung auf mehrere Systeme |

---

# 3. Systemgrenze

## Bestandteil der Lösung

Die Projektlösung umfasst:

- Windows Server 2022
- PowerShell ETL-Skript
- JSON-Dateierstellung
- MongoDB Datenbank
- MongoDB Compass
- Logging
- KPI-Auswertung
- Task Scheduler
- Datenqualitätsprüfung
- Aggregationsabfragen

---

## Nicht Bestandteil der Lösung

Folgende Bereiche gehören nicht zum Projektumfang:

- Cloud-Dienste
- Externe Monitoring-Lösungen
- Echtzeit-Dashboards
- Alarmierung per E-Mail
- Machine Learning
- Mehrserver-Monitoring

---

# 4. Datenquelle

## Herkunft der Daten

Die Daten werden direkt vom Betriebssystem erfasst.

Verwendete Quellen:

| Quelle | Typ |
|----------|-----|
| Win32_OperatingSystem | Systemdaten |
| Win32_Processor | CPU-Daten |
| Win32_LogicalDisk | Laufwerksdaten |
| Get-Process | Prozessinformationen |

---

## Datenformat

Die Rohdaten werden als PowerShell-Objekte erfasst und anschliessend als JSON-Dateien gespeichert.

Beispiel:

```json
{
  "_id": "SERVER01_20260602_1535",
  "Timestamp": "2026-06-02T15:35:00",
  "Computer": "SERVER01",
  "MemoryUsagePercent": 45.7
}
```

---

## Zugriffsmethode

Die Daten werden lokal über:

```powershell
Get-CimInstance
Get-Process
```

abgerufen.

---

# 5. Architektur

## Systemübersicht

```text
Windows Server 2022
        │
        ▼
PowerShell ETL Script
        │
        ├──────────────► Logging
        │
        ▼
Datenerfassung
        │
        ▼
Transformation
        │
        ▼
Datenqualitätsprüfung
        │
        ▼
JSON Speicherung
        │
        ▼
MongoDB Upsert
        │
        ▼
MongoDB Datenbank
        │
        ▼
Aggregationen & KPIs
        │
        ▼
MongoDB Compass
```

---

## ETL-Prozess

### Extract

Erfassung von:

- Betriebssystemdaten
- CPU-Informationen
- RAM-Nutzung
- Laufwerksinformationen
- Top-Prozessen

### Transform

Berechnung von:

- Speicherauslastung
- Laufwerksauslastung
- Kritische Laufwerke
- KPI-Werten

### Load

Speicherung:

- JSON-Datei
- MongoDB Collection

Verwendung von:

```text
Upsert
```

anstelle von einfachem Insert.

---

# 6. Big Data Bezug

MongoDB dient als persistenter Datenspeicher für historische Leistungsdaten.

Durch die automatische Erfassung im 5-Minuten-Intervall entsteht über längere Zeiträume eine wachsende Datenbasis, welche mittels Aggregationen und KPI-Auswertungen analysiert werden kann.


Big-Data-Aspekte:

- Langfristige Datenspeicherung
- Historische Trendanalyse
- Aggregationen
- KPI-Berechnung
- Strukturierte Dokumentdatenbank

---

# 7. Aufwandsschätzung

| Aufgabe | Verantwortlich | Aufwand |
|------------|-------------|-----------|
| Projektanalyse | Team | 1 h |
| Konzept erstellen | Team | 2 h |
| MongoDB Installation | Team | 1 h |
| PowerShell Entwicklung | Team | 3 h |
| Logging & Fehlerbehandlung | Team | 1 h |
| MongoDB Integration | Team | 1 h |
| Aggregationen | Team | 1 h |
| Dokumentation | Team | 2 h |
| Präsentation vorbereiten | Team | 1 h |

**Gesamtaufwand: ca. 15–20 Stunden

---

# 8. Hilfsmittel

## Software

| Produkt | Zweck |
|-----------|--------|
| Windows Server 2022 | Betriebssystem |
| PowerShell 5.1 | Skriptentwicklung |
| MongoDB Community Server | Datenbank |
| mongosh | Datenbankzugriff |
| MongoDB Compass | GUI |
| Visual Studio Code | Entwicklung |
| Git | Versionsverwaltung |
| GitHub | Repository |

---

## Lizenzen

| Produkt | Lizenz |
|-----------|----------|
| PowerShell | Kostenlos |
| MongoDB Community | Kostenlos |
| MongoDB Compass | Kostenlos |
| Visual Studio Code | Kostenlos |
| Git | Open Source |

---

# 9. Risiken

| Risiko | Gegenmassnahme |
|-----------|----------------|
| MongoDB nicht erreichbar | Fehlerbehandlung implementieren |
| Fehlerhafte Daten | Datenqualitätsprüfung |
| Duplikate | Upsert-Logik |
| Scriptfehler | Logging und try/catch |
| Fehlende Historie | Automatisierte Ausführung |

---

# 10. Fazit

Mit diesem Projekt wird eine vollständige ETL-Pipeline auf Basis von PowerShell und MongoDB umgesetzt. Die Lösung automatisiert die Erfassung von Systemleistungsdaten, verarbeitet diese strukturiert und speichert sie langfristig für spätere Analysen.

Die Anwendung erfüllt die Anforderungen der Projektarbeit in den Bereichen Skripting, Datenverarbeitung, Datenbankintegration, Automatisierung, Logging, Fehlerbehandlung und KPI-Auswertung.