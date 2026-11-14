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

**Starting point (unnormalised):** a single flat visit record such as
`Visit(patient_name, patient_phone, doctor_name, doctor_specialty, department_name, department_location, visit_time, diagnosis, medications[], lab_tests[])`

**1NF:** Remove repeating groups. `medications[]` and `lab_tests[]` are multi-valued, so each becomes its own row (prescription_item, lab_result). Every column now holds one atomic value and every row has a primary key.

**2NF:** Remove partial dependencies. In `prescription_item`, the key is (prescription_id, medication_id). Medication attributes (name, form, unit_price) depend only on `medication_id`, so they moved to `medication`. Test attributes (normal_range, unit) depend only on the test type, so they moved to `lab_test_type`.

**3NF:** Remove transitive dependencies. In the flat visit, `department_location` depends on `department_name`, which depends on the doctor (doctor_id -> department -> location). Extracting `department` removes that transitive chain. Doctor details depend only on `doctor_id`, patient details only on `patient_id`.

**Result:** every non-key attribute depends on the key, the whole key, and nothing but the key. All tables are in 3NF. Each is also in BCNF, since every determinant is a candidate key (for example `licence_no` and `doctor_id` both determine the same doctor row).

**Deliberate trade-off:** `medication.unit_price` is the current price. A production system might snapshot price at prescription time in `prescription_item`; this is noted for the reflection.

## 5. How to run and test

```bash
psql -U postgres -c "CREATE DATABASE clinic_db;"
psql -U postgres -d clinic_db -f schema.sql
psql -U postgres -d clinic_db -c "\dt clinic.*"
```

Take screenshots of the `\dt` and `\d clinic.appointment` output as implementation evidence.
