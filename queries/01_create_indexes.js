use("skt_bigdata")

db.system_performance.createIndex({
    Timestamp: -1
})

db.system_performance.createIndex({
    Computer: 1,
    Timestamp: -1
})