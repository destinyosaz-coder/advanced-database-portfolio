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

## 5. SQL vs NoSQL: which fits better

**1. Tasks well suited to MongoDB.** Retrieving a single patient's complete history is best handled by MongoDB. All information about a patient (visits, diagnoses, prescriptions, lab results) lives in a single document, so one read delivers the full picture, whereas PostgreSQL requires a join across multiple tables. In my seeded database, I opened one patient document in the shell and saw all of that patient's visits inside a single `visits` array. Adding a new visit with `$push` (script 03) is likewise straightforward, and documents can vary in their fields from one visit to the next, such as visits without lab tests.

**2. Tasks well suited to PostgreSQL.** Scheduling appointments is better handled by PostgreSQL. In Portfolio 3, the UNIQUE constraint and transactions prevented two receptionists from booking the same doctor at the same moment. Reports that join many tables, along with data involving strict relationships such as doctors, departments and medicines, are also easier to keep accurate in a relational database.

**3. The cost of embedding.** Putting visits inside the patient document speeds up reads, but it comes at a price. Every visit keeps a copy of the doctor's name and department, so when a doctor moves to another department, many patient documents have to be updated. A patient with numerous visits also causes the document to grow, and MongoDB caps a document at 16 MB. Indexes reduce the work done by a query: in script 05, adding an index on `lastName` changed the plan from a collection scan (COLLSCAN) to an index scan (IXSCAN), and the number of documents examined fell from 5,000 to 415. The index on `visits.doctor.id` did the same, from 5,000 to 875 documents. The measured time was actually higher after the indexes (29 ms compared with 11 ms), but with only 5,000 documents the timings are very small and are probably affected by caching and first use of the new index, so I treat documents examined as the more reliable measure. On a much larger collection, the saving would show clearly in the time as well.

**4. When to reference rather than embed.** I stored doctors in their own `doctors` collection as references because many patients share the same doctor and doctor details change on their own. Broadly, I reference data that is shared, changes frequently, or can grow without limit, and I embed data that is read together and belongs to a single parent.

**5. A hybrid approach.** I would not swap PostgreSQL for MongoDB. A hybrid design suits the clinic: PostgreSQL for bookings, billing and anything requiring strict consistency, and MongoDB for fast patient-history views that are read often. If I built it in stages, I would start with the patient-history view in MongoDB, because it is the most read-heavy part of the clinic. The difficulty lies in keeping the two synchronized, for instance by updating MongoDB each time a booking is completed in PostgreSQL.

## 6. Evidence checklist
- [ ] Compass screenshot of the collections
- [ ] Output of 01 (collections created) and 02 (counts)
- [ ] Output of 03 including the validation rejection
- [ ] Output of 04 (aggregations)
- [ ] Output of 05 (before/after index)
