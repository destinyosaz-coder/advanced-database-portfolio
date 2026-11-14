# Portfolio 4: NoSQL and Advanced Data Models

**Course:** MIT 8103 Advanced Database Systems | **Student:** Destiny Osazuwa (301908420)
**NoSQL database:** MongoDB (document model) | **Case study:** Lagos Community Clinic (same as Portfolios 1 to 3)

## 1. Why a document database for part of the clinic?
A patient's history is read as one story: patient, then visits, then diagnoses, prescriptions and lab results. In PostgreSQL this takes a join across up to seven tables. In MongoDB the whole history sits in **one document**, so one read returns it.

## 2. Data model

| Collection | Holds | Design choice |
|---|---|---|
| `patients` | One document per patient, with `contact` and a `visits` array. Each visit embeds its `doctor` summary, `diagnoses`, `prescriptions` and `labResults` | **Embedding**: data read together is stored together |
| `doctors` | One document per doctor | **Referencing**: doctors are shared by many patients and change on their own, so each visit keeps only a small summary (`id`, `name`, `department`) |

Example document shape (simplified):
```json
{
  "patientId": 1, "firstName": "Chioma", "lastName": "Okafor", "gender": "F",
  "contact": { "phone": "0802...", "email": "..." },
  "visits": [
    { "visitId": 15, "date": "2024-01-12", "status": "COMPLETED",
      "doctor": { "id": 12, "name": "Dr Eze", "department": "Surgery" },
      "diagnoses": [ { "icd": "B54", "description": "Unspecified malaria" } ],
      "prescriptions": [ { "medication": "Artemether-Lumefantrine", "days": 3 } ],
      "labResults": [ { "test": "Malaria parasite", "result": "Positive" } ] }
  ]
}
```

**Schema validation:** both collections use `$jsonSchema` validators (required fields, gender must be M/F/O, visit status from a fixed list), which keeps NoSQL data disciplined.

## 3. Files (run in this order)

| File | What it does |
|---|---|
| `scripts/01_setup_validation.js` | Creates the collections, validators and unique indexes |
| `scripts/02_seed.js` | Loads 20 doctors, 5,000 patients and about 20,000 embedded visits |
| `scripts/03_crud_operations.js` | Insert, find, `$push`, `$set`, validation rejection, delete |
| `scripts/04_aggregations.js` | Four aggregation pipelines for reporting |
| `scripts/05_indexes_explain.js` | `explain("executionStats")` before and after indexes |

## 4. How to run
In Git Bash or PowerShell, from this folder:
```
mongosh "mongodb://localhost:27017/clinic_nosql" --file scripts/01_setup_validation.js
mongosh "mongodb://localhost:27017/clinic_nosql" --file scripts/02_seed.js
```
and so on for 03, 04 and 05. Screenshot each output. Also screenshot the `clinic_nosql` database in MongoDB Compass.

## 5. SQL versus NoSQL: suitability (write in your own words)
Answer each in 2 to 3 sentences:
1. **Which clinic operations suit MongoDB?** (reading one patient's full history; adding a visit with `$push`)
2. **Which suit PostgreSQL better?** (booking with no double-booking, as in Portfolio 3; money-style consistency)
3. **What is the cost of embedding?** (duplicated doctor summary; a document can grow large; updating a doctor's department means updating many documents)
4. **When would you reference instead of embed?** (shared data that changes independently, as with doctors)
5. **Would you replace PostgreSQL entirely?** Explain a hybrid design: PostgreSQL for transactions, MongoDB for patient history views.

## 6. Evidence checklist
- [ ] Compass screenshot of the collections
- [ ] Output of 01 (collections created) and 02 (counts)
- [ ] Output of 03 including the validation rejection
- [ ] Output of 04 (aggregations)
- [ ] Output of 05 (before/after index)
