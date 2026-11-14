# Portfolio 1: Database Design and Modelling

**Course:** MIT 8103 Advanced Database Systems | **Student:** Destiny Osazuwa (301908420)

## 1. Selected case study

| Item | Description |
|---|---|
| **Organisation / scenario** | Lagos Community Clinic (simulated), a mid-sized outpatient clinic with several departments |
| **Nature of the system** | Clinic management database covering appointments, diagnoses, prescriptions and laboratory results |
| **Users of the database** | Receptionists (register patients, book appointments), doctors (record diagnoses, prescribe), lab technicians (enter results), pharmacists (read prescriptions), administrators (reporting) |
| **Major data stored** | Patients, doctors, departments, appointments, diagnoses, medications, prescriptions and line items, lab test types and results |
| **Key operations supported** | Book/cancel appointment, store diagnosis, issue prescription, record lab result, retrieve a patient's full history, report doctor workload |

This same case study is reused in Portfolios 2 to 5.

## 2. ER diagram

See [er-diagram.md](er-diagram.md) (Mermaid; renders on GitHub). Export a PNG screenshot of it for the LMS submission.

## 3. Relational schema, keys and constraints

Full DDL is in [schema.sql](schema.sql). Summary:

| Table | Primary key | Foreign keys | Notable constraints |
|---|---|---|---|
| department | department_id | none | name UNIQUE |
| doctor | doctor_id | department_id | licence_no UNIQUE, email UNIQUE |
| patient | patient_id | none | gender IN (M,F,O); date_of_birth not in future |
| appointment | appointment_id | patient_id, doctor_id | UNIQUE (doctor_id, appointment_time); status CHECK |
| diagnosis | diagnosis_id | appointment_id | ON DELETE CASCADE |
| medication | medication_id | none | unit_price >= 0; name UNIQUE |
| prescription | prescription_id | appointment_id | ON DELETE CASCADE |
| prescription_item | (prescription_id, medication_id) | both | duration_days > 0; quantity > 0 |
| lab_test_type | test_type_id | none | name UNIQUE |
| lab_result | lab_result_id | appointment_id, test_type_id | ON DELETE CASCADE on appointment |

**Design choices**
- Surrogate integer keys (`SERIAL`) keep joins fast and stable; natural identifiers such as `licence_no` are kept as `UNIQUE` candidate keys.
- Clinical history (diagnosis, prescription, lab result) hangs off `appointment`, so every clinical record is traceable to a visit, a patient and a doctor.
- Deleting patients or doctors is `RESTRICT`ed to protect medical records; child clinical rows `CASCADE` only when their appointment is removed.
- The `UNIQUE (doctor_id, appointment_time)` constraint stops double-booking at the database level, not only in application code.

## 4. Normalisation explanation

### Starting point (unnormalised)
At first, everything about a visit could be kept in one flat record:

`Visit(patient_name, patient_phone, doctor_name, doctor_specialty, department_name, department_location, visit_time, diagnosis, medications[], lab_tests[])`

For example, Ada visits Dr Bello on 5 March with malaria. She is given **Ampiclox** and **paracetamol**, and a malaria parasite test is done. All of that sits in one row:

| patient | doctor | department | location | medications | lab_tests |
|---|---|---|---|---|---|
| Ada | Dr Bello | Surgery | Block D | Ampiclox, Paracetamol | Malaria parasite |

This causes problems. Two medicines are squeezed into one cell. Dr Bello's department and its location are repeated on every visit he handles, so if the department's location changes, many rows must be corrected.

### First normal form (1NF)
A table is in 1NF when every cell holds one value and there are no repeating groups. The `medications[]` and `lab_tests[]` fields are repeating groups, because Ada received two medicines in one visit. I fixed this by giving each medicine its own row in `prescription_item` (one row for Ampiclox, one for paracetamol) and each test its own row in `lab_result`. Now every column holds one value and every row is identified by a primary key.

### Second normal form (2NF)
A table is in 2NF when every attribute depends on the whole primary key, not only part of it. The key of `prescription_item` is (`prescription_id`, `medication_id`). In the unnormalised design, the medicine's `name`, `form` and `unit_price` sat in the same row, but they depend only on `medication_id`. Ampiclox is always Ampiclox, whoever it is prescribed to. So they were moved to the `medication` table. In the same way, `normal_range` and `unit` depend only on the type of test, not on one patient's result, so they were moved from `lab_result` to `lab_test_type`.

### Third normal form (3NF)
A table is in 3NF when no non-key attribute depends on another non-key attribute. In the flat record, `department_location` depends on the department, and the department depends on the doctor (`doctor_id → department → location`). This chain is a transitive dependency. I removed it by creating a `department` table that stores the location once, and the `doctor` table keeps only `department_id`. Doctor details depend only on `doctor_id`, and patient details only on `patient_id`.

### Result
Every non-key attribute now depends on the key, the whole key, and nothing but the key, so all tables are in 3NF. They are also in BCNF, because every determinant is a candidate key (for example, `licence_no` and `doctor_id` both identify the same doctor row). If a department's location changes, I update one row instead of hundreds. The cost is that some queries now need joins, which I accept for data that stays consistent.

### Deliberate trade-off
`medication.unit_price` stores the current price. A real system might copy the price into `prescription_item` when the prescription is issued, so that old prescriptions keep the price they were sold at.

## 5. How to run and test

```bash
psql -U postgres -c "CREATE DATABASE clinic_db;"
psql -U postgres -d clinic_db -f schema.sql
psql -U postgres -d clinic_db -c "\dt clinic.*"
```

Take screenshots of the `\dt` and `\d clinic.appointment` output as implementation evidence.
