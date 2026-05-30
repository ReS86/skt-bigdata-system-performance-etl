use("skt_bigdata")

db.system_performance.countDocuments()

db.system_performance.find().limit(5)

db.system_performance.find()
  .sort({ Timestamp: -1 })
  .limit(5)