// Writes one record to the PRIMARY and waits until a MAJORITY of nodes have it.
// Run with the replica-set address so mongosh finds the primary by itself:
//   mongosh "mongodb://localhost:27018,localhost:27019,localhost:27020/?replicaSet=clinicRS" --file rs_03_write.js
const clinic = db.getSiblingDB("clinic_replica");
const label = "visit-" + new Date().toISOString();
clinic.visits.insertOne(
  { label: label, patientId: 1, reason: "Fever", at: new Date() },
  { writeConcern: { w: "majority" } }
);
print("Wrote: " + label);
print("Written via PRIMARY: " + db.hello().primary);
print("Total records: " + clinic.visits.countDocuments());
