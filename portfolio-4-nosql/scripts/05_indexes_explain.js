// 05_indexes_explain.js: indexing evidence with explain("executionStats")
// Run: mongosh "mongodb://localhost:27017/clinic_nosql" --file 05_indexes_explain.js
function stats(label, cursor) {
  const e = cursor.explain("executionStats");
  const winning = JSON.stringify(e.queryPlanner.winningPlan);
  const stage = winning.includes("IXSCAN") ? "IXSCAN (index used)" : "COLLSCAN (full scan)";
  print(label + " -> " + stage + " | docsExamined=" + e.executionStats.totalDocsExamined +
        " | returned=" + e.executionStats.nReturned + " | time=" + e.executionStats.executionTimeMillis + " ms");
}
for (const name of ["lastName_1", "visits.doctor.id_1"]) {
  try { db.patients.dropIndex(name); } catch (e) { /* index not there yet: fine */ }
}

print("--- BEFORE indexes ---");
stats("Find by last name", db.patients.find({ lastName: "Okafor" }));
stats("Find by doctor id inside visits", db.patients.find({ "visits.doctor.id": 5 }));

db.patients.createIndex({ lastName: 1 });
db.patients.createIndex({ "visits.doctor.id": 1 });   // multikey index on an array field

print("--- AFTER indexes ---");
stats("Find by last name", db.patients.find({ lastName: "Okafor" }));
stats("Find by doctor id inside visits", db.patients.find({ "visits.doctor.id": 5 }));
