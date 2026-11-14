// =====================================================================
// MIT 8103 - Portfolio 4: NoSQL (MongoDB)  |  Lagos Community Clinic
// 01_setup_validation.js: create collections with schema validation
// Run:  mongosh "mongodb://localhost:27017/clinic_nosql" --file 01_setup_validation.js
// =====================================================================
db.patients.drop();
db.doctors.drop();

// DOCTORS: small reference collection (referenced, not embedded)
db.createCollection("doctors", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["doctorId", "firstName", "lastName", "department", "licenceNo"],
    properties: {
      doctorId:   { bsonType: "int" },
      firstName:  { bsonType: "string" },
      lastName:   { bsonType: "string" },
      department: { bsonType: "string" },
      specialty:  { bsonType: "string" },
      licenceNo:  { bsonType: "string" }
    }
  }}
});
db.doctors.createIndex({ licenceNo: 1 }, { unique: true });
db.doctors.createIndex({ doctorId: 1 }, { unique: true });

// PATIENTS: one document per patient, with visits EMBEDDED inside it
db.createCollection("patients", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["patientId", "firstName", "lastName", "dob", "gender", "visits"],
    properties: {
      patientId: { bsonType: "int" },
      firstName: { bsonType: "string" },
      lastName:  { bsonType: "string" },
      dob:       { bsonType: "date" },
      gender:    { enum: ["M", "F", "O"] },
      contact:   { bsonType: "object" },
      visits: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["visitId", "date", "status", "doctor"],
          properties: {
            status: { enum: ["SCHEDULED", "COMPLETED", "CANCELLED", "NO_SHOW"] }
          }
        }
      }
    }
  }},
  validationAction: "error"
});
db.patients.createIndex({ patientId: 1 }, { unique: true });

print("Collections created:");
printjson(db.getCollectionNames());
