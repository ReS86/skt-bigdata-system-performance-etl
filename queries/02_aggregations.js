use("skt_bigdata")

print("1. Durchschnittliche RAM-Auslastung")
db.system_performance.aggregate([
  { $group: { _id: "$Computer", avgMemoryUsage: { $avg: "$MemoryUsagePercent" } } }
]).forEach(printjson)

print("2. Letzte 3 Messungen")
db.system_performance.find()
  .sort({ Timestamp: -1 })
  .limit(3)
  .forEach(printjson)

print("3. Kritische Laufwerke")
db.system_performance.aggregate([
  { $unwind: "$Disks" },
  { $match: { "Disks.CriticalFreeSpace": true } },
  { $group: { _id: "$Computer", criticalDisks: { $sum: 1 } } }
]).forEach(printjson)