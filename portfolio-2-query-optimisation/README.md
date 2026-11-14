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

## 3. Experiments (fill in YOUR numbers)

Run `optimisation.sql` block by block and copy the `Execution Time` from your own screenshots. Timings differ between machines, so use yours, not these.

| Exp | Query | Index created | Plan before | Plan after | Time before | Time after |
|---|---|---|---|---|---|---|
| 1 | Q1 cancelled in date range | `(status, appointment_time)` | Seq Scan | Bitmap Index Scan | ___ ms | ___ ms |
| 2 | Q2 last name search | `(last_name)` | Seq Scan | Bitmap Index Scan | ___ ms | ___ ms |
| 3 | Q6 one patient's visits | `(patient_id)` removed, then restored | Index scan with, Seq Scan without | | ___ ms | ___ ms |
| 4 | Q4 top medications | `(medication_id)` | Seq Scan | Seq Scan (no change) | ___ ms | ___ ms |

## 4. Analysis (write this in your own words)

Answer each question in two or three sentences:

1. **Why did Experiment 1 become faster?** (Think: the database no longer reads every row, it jumps to the matching ones. Why is `status` listed before `appointment_time` in the index?)
2. **Why was the gain in Experiment 2 smaller than in Experiment 1?** (Hint: how many rows matched? An index helps most when it selects a small fraction of the table.)
3. **What does Experiment 3 show about foreign keys?** (PostgreSQL does not index foreign keys automatically.)
4. **Why did Experiment 4 not improve?** (The query needs every row of the table, so an index has nothing to skip.)
5. **What is the cost of an index?** (Extra disk space, slower INSERT/UPDATE.)

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
