-- =====================================================================
-- MIT 8103 - Portfolio 2: queries.sql
-- Eight clinic queries. Each one is written on its own block so you can
-- highlight a block and press F5 in pgAdmin to run it by itself.
-- Reference date 2025-06-01 is used because the data is synthetic.
-- =====================================================================
SET search_path TO clinic;

-- Q1: Cancelled appointments in a date range (filtering on 2 columns)
SELECT appointment_id, patient_id, doctor_id, appointment_time
FROM appointment
WHERE status = 'CANCELLED'
  AND appointment_time >= '2024-06-01' AND appointment_time < '2024-07-01';

-- Q2: Find patients by last name (reception search)
SELECT patient_id, first_name, last_name, phone
FROM patient
WHERE last_name = 'Okafor';

-- Q3: Doctor workload: completed appointments per doctor, with department
SELECT d.doctor_id, d.first_name || ' ' || d.last_name AS doctor, dep.name AS department,
       count(*) AS completed_visits
FROM appointment a
JOIN doctor d       ON d.doctor_id = a.doctor_id
JOIN department dep ON dep.department_id = d.department_id
WHERE a.status = 'COMPLETED'
GROUP BY d.doctor_id, doctor, dep.name
ORDER BY completed_visits DESC;

-- Q4: Ten most prescribed medications
SELECT m.name, count(*) AS times_prescribed, sum(pi.quantity) AS total_units
FROM prescription_item pi
JOIN medication m ON m.medication_id = pi.medication_id
GROUP BY m.name
ORDER BY times_prescribed DESC
LIMIT 10;

-- Q5: Rank doctors inside each department (window function)
SELECT department, doctor, completed_visits,
       RANK() OVER (PARTITION BY department ORDER BY completed_visits DESC) AS rank_in_dept
FROM (
    SELECT dep.name AS department, d.first_name || ' ' || d.last_name AS doctor,
           count(*) AS completed_visits
    FROM appointment a
    JOIN doctor d       ON d.doctor_id = a.doctor_id
    JOIN department dep ON dep.department_id = d.department_id
    WHERE a.status = 'COMPLETED'
    GROUP BY dep.name, doctor
) t
ORDER BY department, rank_in_dept;

-- Q6: Complete history for one patient (4-way join)
SELECT a.appointment_time, d.last_name AS doctor, a.status,
       dg.description AS diagnosis, m.name AS medication, lt.name AS lab_test, lr.result_value
FROM appointment a
JOIN doctor d                 ON d.doctor_id = a.doctor_id
LEFT JOIN diagnosis dg        ON dg.appointment_id = a.appointment_id
LEFT JOIN prescription p      ON p.appointment_id = a.appointment_id
LEFT JOIN prescription_item pi ON pi.prescription_id = p.prescription_id
LEFT JOIN medication m        ON m.medication_id = pi.medication_id
LEFT JOIN lab_result lr       ON lr.appointment_id = a.appointment_id
LEFT JOIN lab_test_type lt    ON lt.test_type_id = lr.test_type_id
WHERE a.patient_id = 1234
ORDER BY a.appointment_time;

-- Q7: Patients with no visit since 2025-01-01 (anti-join with NOT EXISTS)
SELECT p.patient_id, p.first_name, p.last_name
FROM patient p
WHERE NOT EXISTS (
    SELECT 1 FROM appointment a
    WHERE a.patient_id = p.patient_id AND a.appointment_time >= '2025-01-01'
);

-- Q8: Monthly appointment volume (time-series aggregate)
SELECT date_trunc('month', appointment_time)::date AS month, count(*) AS appointments
FROM appointment
GROUP BY 1
ORDER BY 1;
