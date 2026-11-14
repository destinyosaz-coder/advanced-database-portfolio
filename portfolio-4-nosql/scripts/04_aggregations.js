// 04_aggregations.js: analytics with the aggregation pipeline
// Run: mongosh "mongodb://localhost:27017/clinic_nosql" --file 04_aggregations.js
print("=== AGG 1: completed visits per department ===");
db.patients.aggregate([
  { $unwind: "$visits" },
  { $match: { "visits.status": "COMPLETED" } },
  { $group: { _id: "$visits.doctor.department", completedVisits: { $sum: 1 } } },
  { $sort: { completedVisits: -1 } }
]).forEach(printjson);

print("\n=== AGG 2: top 5 diagnoses ===");
db.patients.aggregate([
  { $unwind: "$visits" }, { $unwind: "$visits.diagnoses" },
  { $group: { _id: "$visits.diagnoses.description", cases: { $sum: 1 } } },
  { $sort: { cases: -1 } }, { $limit: 5 }
]).forEach(printjson);

print("\n=== AGG 3: appointments per month ===");
db.patients.aggregate([
  { $unwind: "$visits" },
  { $group: { _id: { $dateToString: { format: "%Y-%m", date: "$visits.date" } }, appointments: { $sum: 1 } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

print("\n=== AGG 4: five most frequent patients (by number of visits) ===");
db.patients.aggregate([
  { $project: { _id: 0, patientId: 1, firstName: 1, lastName: 1, visitCount: { $size: "$visits" } } },
  { $sort: { visitCount: -1 } }, { $limit: 5 }
]).forEach(printjson);
