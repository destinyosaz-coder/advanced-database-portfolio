# Portfolio 2: Query Processing and Optimisation

**Course:** MIT 8103 Advanced Database Systems | **Student:** Destiny Osazuwa (301908420)
**Database:** PostgreSQL 18 | **Case study:** Lagos Community Clinic (same schema as Portfolio 1)

## 1. Files

| File | Purpose |
|---|---|
| `seed.sql` | Loads synthetic data: 20,000 patients, 100,000 appointments, plus diagnoses, prescriptions, lab results |
| `queries.sql` | Eight clinic queries (Q1 to Q8) |
| `optimisation.sql` | Four before/after indexing experiments using `EXPLAIN (ANALYZE, BUFFERS)` |
| `evidence/` | Your screenshots of plans and timings |

## 2. The eight queries

| # | Business question | SQL features |
|---|---|---|
| Q1 | Cancelled appointments in June 2024 | filter on two columns |
| Q2 | Find patients by last name | equality filter |
| Q3 | Completed visits per doctor, with department | 2 joins, GROUP BY |
| Q4 | Ten most prescribed medications | join, aggregate, LIMIT |
| Q5 | Rank doctors inside each department | subquery, window function `RANK()` |
| Q6 | Full history of one patient | multi-table LEFT JOIN |
| Q7 | Patients with no visit since 2025 | `NOT EXISTS` anti-join |
| Q8 | Appointments per month | `date_trunc`, GROUP BY |

## 3. Experiments

| Exp | Query | Index created | Plan before | Plan after | Time before | Time after |
|---|---|---|---|---|---|---|
| 1 | Q1: cancelled appointments in a date range | `(status, appointment_time)` | Bitmap scan on `uq_doctor_slot` | Bitmap scan on `idx_appt_status_time` | 4.364 ms | 1.513 ms |
| 2 | Q2: patients by last name | `(last_name)` | Seq Scan | Bitmap scan on `idx_patient_last_name` | 18.621 ms | 6.589 ms |
| 3 | Q6: one patient's visits | `(patient_id)` removed, then restored | With index: Bitmap scan on `idx_appt_patient` | Without index: Seq Scan | 0.209 ms | 41.233 ms |
| 4 | Q4: top medications | `(medication_id)` | Seq Scan on `prescription_item` | Seq Scan (index not used) | about 40.4 ms | about 59.6 ms |

## 4. Analysis

**Experiment 1.** The composite index on `(status, appointment_time)` reduced the time from 4.364 ms to 1.513 ms, about three times faster. Before it, PostgreSQL 18 was already using the unique index `uq_doctor_slot` to find rows in the date range, but it still had to check the status of each row and removed 8,606 rows by filter. With the new index, it goes straight to the cancelled rows in that range. I put `status` first because it is an equality test, and `appointment_time` second because it is a range.

**Experiment 2.** The index on `last_name` changed a sequential scan (18.621 ms) into a bitmap index scan (6.589 ms), nearly three times faster. The gain is smaller than in Experiment 3 because the search matched 1,667 of the 20,000 patients, which is about 8% of the table. An index helps most when it selects only a small part of the table.

**Experiment 3.** Looking up one patient's appointments took 0.209 ms with the index on `patient_id`, but 41.233 ms without it, because PostgreSQL had to scan all 100,000 rows and discard 99,993 of them. The index made the query about 200 times faster. This shows that PostgreSQL does not create indexes on foreign keys automatically, so I must add them where I search or join by those columns.

**Experiment 4.** The index on `medication_id` did not change the plan. PostgreSQL still did a sequential scan of `prescription_item` (26,131 rows) and a hash join, both before and after the index. The query has to read every row to count the prescriptions per medicine, so there is nothing for an index to skip. The time was about 40.4 ms before and 59.6 ms after, but the plan is identical, so this difference is normal run-to-run variation (caching and background activity), not an effect of the index. This shows that an index only helps queries that select a small part of the table.

**Cost of indexes.** Every index uses extra disk space and makes inserts and updates slower, because the index must be updated too. So I should create indexes only for queries that need them, such as the patient lookup, and not for queries that read the whole table.

## 5. Evidence checklist

- [ ] Screenshot of row counts after `seed.sql`
- [ ] Before and after `EXPLAIN ANALYZE` for experiments 1, 2 and 3
- [ ] Before and after for experiment 4
- [ ] Output of at least Q3 and Q5

## 6. How to run

1. Run Portfolio 1 `schema.sql` first (it recreates the `clinic` schema empty).
2. Run `seed.sql` (takes about 10 seconds).
3. Run queries from `queries.sql`, one block at a time.
4. Run `optimisation.sql` block by block, screenshotting each plan.
