// Simulates the PRIMARY failing: it steps down and the others elect a new one.
//   mongosh "mongodb://localhost:27018,localhost:27019,localhost:27020/?replicaSet=clinicRS" --file rs_05_failover.js
print("Primary BEFORE: " + db.hello().primary);
try { db.adminCommand({ replSetStepDown: 60, force: true }); } catch (e) { print("(connection dropped as expected during step-down)"); }
