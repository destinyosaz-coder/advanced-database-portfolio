-- =====================================================================
-- MIT 8103 - Portfolio 2: Query Processing and Optimisation
-- File: seed.sql  (run AFTER Portfolio 1 schema.sql)
-- Purpose: load realistic synthetic clinic data large enough for
--          execution plans to be meaningful.
-- Volume: 5 departments, 20 doctors, 20,000 patients, 100,000 appointments
-- Data is synthetic (no real patients). setseed() makes it reproducible.
-- =====================================================================
SET search_path TO clinic;
SELECT setseed(0.42);

-- Departments ----------------------------------------------------------
INSERT INTO department (name, location) VALUES
 ('General Medicine','Block A'), ('Paediatrics','Block B'),
 ('Obstetrics & Gynaecology','Block C'), ('Surgery','Block D'),
 ('Laboratory & Diagnostics','Block E');

-- Doctors (20) ---------------------------------------------------------
INSERT INTO doctor (department_id, first_name, last_name, specialty, licence_no, email, phone)
SELECT 1 + (g % 5),
       (ARRAY['Ngozi','Tunde','Amina','Chidi','Funke','Ibrahim','Kemi','Emeka','Zainab','Segun'])[1 + g % 10],
       (ARRAY['Adeyemi','Okafor','Bello','Eze','Balogun','Musa','Nwosu','Ogunleye'])[1 + g % 8],
       (ARRAY['General Practice','Paediatrics','Obstetrics','General Surgery','Pathology'])[1 + g % 5],
       'MDCN-' || (10000 + g),
       'doctor' || g || '@lagosclinic.example',
       '0801' || lpad(g::text, 7, '0')
FROM generate_series(1, 20) g;

-- Patients (20,000) ----------------------------------------------------
INSERT INTO patient (first_name, last_name, date_of_birth, gender, phone, email, address, registered_on)
SELECT (ARRAY['Chioma','Tunde','Aisha','Emeka','Folake','Musa','Ngozi','Bayo','Hauwa','Ifeanyi',
              'Sade','Uche','Kehinde','Yusuf','Bisi'])[1 + (g % 15)],
       (ARRAY['Adeyemi','Okafor','Bello','Eze','Balogun','Musa','Nwosu','Ogunleye',
              'Ibrahim','Okonkwo','Lawal','Adeleke'])[1 + (g % 12)],
       date '1950-01-01' + (random() * 25000)::int,
       (ARRAY['M','F'])[1 + (g % 2)],
       '0802' || lpad(g::text, 7, '0'),
       'patient' || g || '@mail.example',
       (1 + g % 300) || ' Allen Avenue, Ikeja, Lagos',
       date '2023-01-01' + (g % 700)
FROM generate_series(1, 20000) g;

-- Appointments (100,000) ----------------------------------------------
-- Each doctor gets unique half-hour slots, so uq_doctor_slot is respected.
INSERT INTO appointment (patient_id, doctor_id, appointment_time, status, reason)
SELECT 1 + floor(random() * 20000)::int,
       1 + (g % 20),
       timestamp '2024-01-01 08:00' + ((g / 20) / 16) * interval '1 day'
                                    + ((g / 20) % 16) * interval '30 minutes',
       CASE WHEN r < 0.70 THEN 'COMPLETED'
            WHEN r < 0.85 THEN 'SCHEDULED'
            WHEN r < 0.95 THEN 'CANCELLED'
            ELSE 'NO_SHOW' END,
       (ARRAY['Fever','Headache','Routine check-up','Antenatal visit','Wound dressing',
              'Hypertension review','Cough','Child immunisation'])[1 + (g % 8)]
FROM (SELECT g, random() AS r FROM generate_series(0, 99999) g) s;

-- Medications (30) -----------------------------------------------------
INSERT INTO medication (name, form, unit_price)
SELECT 'Medication-' || lpad(g::text, 2, '0'),
       (ARRAY['tablet','syrup','injection','capsule'])[1 + g % 4],
       round((50 + random() * 2000)::numeric, 2)
FROM generate_series(1, 30) g;

-- Lab test types (10) --------------------------------------------------
INSERT INTO lab_test_type (name, normal_range, unit) VALUES
 ('Malaria parasite','Negative',NULL), ('Full blood count','4.0-11.0','x10^9/L'),
 ('Fasting blood glucose','3.9-5.6','mmol/L'), ('Urinalysis','Normal',NULL),
 ('Hepatitis B surface antigen','Negative',NULL), ('Lipid profile','< 5.2','mmol/L'),
 ('Haemoglobin','12.0-16.0','g/dL'), ('Pregnancy test','Negative',NULL),
 ('Widal test','Negative',NULL), ('Creatinine','60-110','umol/L');

-- Diagnoses: for about a third of completed appointments --------------
INSERT INTO diagnosis (appointment_id, icd_code, description, notes)
SELECT appointment_id,
       (ARRAY['B54','J06.9','I10','Z00.0','Z34.9','R51','L03.9','Z23'])[1 + (appointment_id % 8)],
       (ARRAY['Unspecified malaria','Upper respiratory infection','Essential hypertension',
              'General medical examination','Supervision of normal pregnancy','Headache',
              'Cellulitis','Immunisation encounter'])[1 + (appointment_id % 8)],
       'Synthetic note'
FROM appointment
WHERE status = 'COMPLETED' AND appointment_id % 3 = 0;

-- Prescriptions: for a quarter of completed appointments ---------------
INSERT INTO prescription (appointment_id, issued_on)
SELECT appointment_id, appointment_time::date
FROM appointment
WHERE status = 'COMPLETED' AND appointment_id % 4 = 0;

-- Items: 1 to 2 medications per prescription ---------------------------
INSERT INTO prescription_item (prescription_id, medication_id, dosage, duration_days, quantity)
SELECT prescription_id, 1 + (prescription_id % 30), '1 tablet twice daily', 5 + (prescription_id % 10), 10
FROM prescription;

INSERT INTO prescription_item (prescription_id, medication_id, dosage, duration_days, quantity)
SELECT prescription_id, 1 + ((prescription_id + 7) % 30), '1 tablet daily', 7, 7
FROM prescription
WHERE prescription_id % 2 = 0;

-- Lab results: for a fifth of completed appointments -------------------
INSERT INTO lab_result (appointment_id, test_type_id, result_value, tested_on)
SELECT appointment_id, 1 + (appointment_id % 10),
       (ARRAY['Negative','Positive','Normal','High','Low'])[1 + (appointment_id % 5)],
       appointment_time::date
FROM appointment
WHERE status = 'COMPLETED' AND appointment_id % 5 = 0;

-- Refresh planner statistics so execution plans are accurate -----------
ANALYZE;

-- Row counts for the evidence screenshot -------------------------------
SELECT 'department' AS table_name, count(*) FROM department
UNION ALL SELECT 'doctor', count(*) FROM doctor
UNION ALL SELECT 'patient', count(*) FROM patient
UNION ALL SELECT 'appointment', count(*) FROM appointment
UNION ALL SELECT 'diagnosis', count(*) FROM diagnosis
UNION ALL SELECT 'prescription', count(*) FROM prescription
UNION ALL SELECT 'prescription_item', count(*) FROM prescription_item
UNION ALL SELECT 'lab_result', count(*) FROM lab_result
ORDER BY table_name;
