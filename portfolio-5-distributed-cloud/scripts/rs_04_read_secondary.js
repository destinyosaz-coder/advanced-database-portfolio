// Reads from ONE specific node. Run it against each port and compare:
//   mongosh --port 27018 --file rs_04_read_secondary.js
//   mongosh --port 27019 --file rs_04_read_secondary.js
//   mongosh --port 27020 --file rs_04_read_secondary.js
db.getMongo().setReadPref("secondaryPreferred");
const h = db.hello();
print("This node: " + h.me + "  | is primary: " + h.isWritablePrimary + "  | is secondary: " + h.secondary);
print("Records visible here: " + db.getSiblingDB("clinic_replica").visits.countDocuments());
