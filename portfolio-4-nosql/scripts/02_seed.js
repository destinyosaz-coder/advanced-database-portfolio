// 02_seed.js: load synthetic clinic data into MongoDB
// Run: mongosh "mongodb://localhost:27017/clinic_nosql" --file 02_seed.js
// A fixed-seed generator makes the data identical on every run.
let seed = 42;
function rnd() { seed = (seed * 1664525 + 1013904223) % 4294967296; return seed / 4294967296; }
function pick(arr) { return arr[Math.floor(rnd() * arr.length)]; }

const departments = ["General Medicine", "Paediatrics", "Obstetrics & Gynaecology", "Surgery", "Laboratory & Diagnostics"];
const specialties = ["General Practice", "Paediatrics", "Obstetrics", "General Surgery", "Pathology"];
const firstNames  = ["Chioma","Tunde","Aisha","Emeka","Folake","Musa","Ngozi","Bayo","Hauwa","Ifeanyi","Sade","Uche","Kehinde","Yusuf","Bisi"];
const lastNames   = ["Adeyemi","Okafor","Bello","Eze","Balogun","Musa","Nwosu","Ogunleye","Ibrahim","Okonkwo","Lawal","Adeleke"];
const reasons     = ["Fever","Headache","Routine check-up","Antenatal visit","Wound dressing","Hypertension review","Cough","Child immunisation"];
const diagnoses   = [["B54","Unspecified malaria"],["J06.9","Upper respiratory infection"],["I10","Essential hypertension"],["Z00.0","General medical examination"],["R51","Headache"],["Z23","Immunisation encounter"]];
const meds        = ["Paracetamol","Amoxicillin","Artemether-Lumefantrine","Amlodipine","Ibuprofen","Metformin","Vitamin C","ORS Sachet"];
const labs        = [["Malaria parasite",["Negative","Positive"]],["Fasting blood glucose",["Normal","High","Low"]],["Haemoglobin",["Normal","Low"]],["Full blood count",["Normal","High"]]];
const statuses    = ["COMPLETED","COMPLETED","COMPLETED","COMPLETED","SCHEDULED","CANCELLED","NO_SHOW"];

// Doctors
const doctorDocs = [];
for (let i = 1; i <= 20; i++) {
  doctorDocs.push({
    doctorId: NumberInt(i), firstName: pick(firstNames), lastName: pick(lastNames),
    department: departments[i % 5], specialty: specialties[i % 5], licenceNo: "MDCN-" + (10000 + i)
  });
}
db.doctors.insertMany(doctorDocs);

// Patients with embedded visits
let visitCounter = 1;
let batch = [];
const TOTAL_PATIENTS = 5000;
for (let p = 1; p <= TOTAL_PATIENTS; p++) {
  const nVisits = Math.floor(rnd() * 9);          // 0 to 8 visits
  const visits = [];
  for (let v = 0; v < nVisits; v++) {
    const doc = pick(doctorDocs);
    const status = pick(statuses);
    const visit = {
      visitId: NumberInt(visitCounter++),
      date: new Date(Date.UTC(2024, Math.floor(rnd() * 18), 1 + Math.floor(rnd() * 28), 8 + Math.floor(rnd() * 8))),
      status: status,
      reason: pick(reasons),
      doctor: { id: doc.doctorId, name: "Dr " + doc.lastName, department: doc.department },
      diagnoses: [], prescriptions: [], labResults: []
    };
    if (status === "COMPLETED") {
      if (rnd() < 0.5) { const d = pick(diagnoses); visit.diagnoses.push({ icd: d[0], description: d[1] }); }
      if (rnd() < 0.4) { visit.prescriptions.push({ medication: pick(meds), dosage: "1 tablet twice daily", days: 5 + Math.floor(rnd() * 10) }); }
      if (rnd() < 0.3) { const l = pick(labs); visit.labResults.push({ test: l[0], result: pick(l[1]) }); }
    }
    visits.push(visit);
  }
  visits.sort((a, b) => a.date - b.date);
  batch.push({
    patientId: NumberInt(p), firstName: pick(firstNames), lastName: pick(lastNames),
    dob: new Date(Date.UTC(1950 + Math.floor(rnd() * 70), Math.floor(rnd() * 12), 1 + Math.floor(rnd() * 28))),
    gender: pick(["M", "F"]),
    contact: { phone: "0802" + String(1000000 + p), email: "patient" + p + "@mail.example", address: (1 + (p % 300)) + " Allen Avenue, Ikeja, Lagos" },
    visits: visits
  });
  if (batch.length === 1000) { db.patients.insertMany(batch); batch = []; }
}
if (batch.length) db.patients.insertMany(batch);

print("doctors:  " + db.doctors.countDocuments());
print("patients: " + db.patients.countDocuments());
print("visits (embedded): " + db.patients.aggregate([{ $unwind: "$visits" }, { $count: "n" }]).toArray()[0].n);
