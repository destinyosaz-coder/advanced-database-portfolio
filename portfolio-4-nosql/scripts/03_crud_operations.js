// 03_crud_operations.js: Create, Read, Update, Delete + validation demo
// Run: mongosh "mongodb://localhost:27017/clinic_nosql" --file 03_crud_operations.js
print("=== CREATE: register a new patient with a first visit ===");
db.patients.insertOne({
  patientId: NumberInt(900001), firstName: "Destiny", lastName: "Demo", dob: new Date("1995-03-15"), gender: "F",
  contact: { phone: "08031234567", email: "demo@mail.example", address: "12 Marina Road, Lagos" },
  visits: [{
    visitId: NumberInt(900001), date: new Date("2025-01-10T09:00:00Z"), status: "COMPLETED", reason: "Fever",
    doctor: { id: NumberInt(1), name: "Dr Adeyemi", department: "General Medicine" },
    diagnoses: [{ icd: "B54", description: "Unspecified malaria" }],
    prescriptions: [{ medication: "Artemether-Lumefantrine", dosage: "4 tablets twice daily", days: 3 }],
    labResults: [{ test: "Malaria parasite", result: "Positive" }]
  }]
});

print("\n=== READ 1: find the patient (whole history in ONE read, no joins) ===");
printjson(db.patients.findOne({ patientId: 900001 }));

print("\n=== READ 2: patients with a COMPLETED malaria diagnosis (nested query), first 3 ===");
db.patients.find(
  { visits: { $elemMatch: { status: "COMPLETED", "diagnoses.icd": "B54" } } },
  { patientId: 1, firstName: 1, lastName: 1, _id: 0 }
).limit(3).forEach(printjson);

print("\n=== UPDATE 1: add a new visit with $push (no extra table or join) ===");
db.patients.updateOne({ patientId: 900001 }, { $push: { visits: {
  visitId: NumberInt(900002), date: new Date("2025-02-05T10:30:00Z"), status: "SCHEDULED", reason: "Follow-up",
  doctor: { id: NumberInt(1), name: "Dr Adeyemi", department: "General Medicine" },
  diagnoses: [], prescriptions: [], labResults: [] } } });
print("Visits now: " + db.patients.findOne({ patientId: 900001 }).visits.length);

print("\n=== UPDATE 2: change the phone number with $set ===");
db.patients.updateOne({ patientId: 900001 }, { $set: { "contact.phone": "08099999999" } });
print("New phone: " + db.patients.findOne({ patientId: 900001 }).contact.phone);

print("\n=== VALIDATION: try to insert an invalid gender (should be rejected) ===");
try {
  db.patients.insertOne({ patientId: NumberInt(900002), firstName: "Bad", lastName: "Data", dob: new Date("1990-01-01"), gender: "X", visits: [] });
  print("UNEXPECTED: insert succeeded");
} catch (e) { print("Rejected as expected: " + e.message); }

print("\n=== DELETE: remove the demo patient ===");
printjson(db.patients.deleteOne({ patientId: 900001 }));
