# Portfolio 3: Transactions and Concurrency

**Course:** MIT 8103 Advanced Database Systems | **Student:** Destiny Osazuwa (301908420)
**Database:** PostgreSQL 18 | **Case study:** Lagos Community Clinic

## 1. Files
| File | Purpose |
|---|---|
| `transactions.sql` | Exercises A to E, run block by block |
| `evidence/` | Screenshots of each exercise |

## 2. Exercises

| Exercise | Concept | Clinic scenario | What to show |
|---|---|---|---|
| A | COMMIT | Reschedule: cancel old booking and create new one as one unit | Both changes visible after COMMIT |
| B | ROLLBACK | A wrong update multiplies a medication price by 10 | Price back to original after ROLLBACK |
| C | Atomicity | Second INSERT breaks a CHECK constraint | Valid first INSERT is also undone (count = 0) |
| D | Concurrency control | Two receptionists book the same doctor slot | Second session waits, then fails with `uq_doctor_slot` |
| E | Isolation levels | A price is read twice while another session changes it | READ COMMITTED value changes; REPEATABLE READ stays the same |

## 3. Analysis (write in your own words, 2 to 3 sentences each)
1. **What does ACID atomicity mean, and which exercise shows it?** (Exercise C)
2. **Why did session 2 wait in Exercise D instead of failing straight away?** (It had to learn whether session 1 would commit or roll back.)
3. **What would happen in Exercise D without the UNIQUE constraint?** (A double booking: two patients for one slot.)
4. **Explain the difference between READ COMMITTED and REPEATABLE READ using Exercise E.**
5. **Which isolation level would you choose for the clinic, and why?** Mention the trade-off between consistency and concurrency.

## 4. Evidence checklist
- [ ] A: result after COMMIT
- [ ] B: price before, inside the transaction, after ROLLBACK
- [ ] C: the error message and the final count of 0
- [ ] D: session 2 waiting, then the duplicate key error
- [ ] E: both isolation levels, with the two reads side by side

## 5. How to run
Use `transactions.sql` from the top. Run the CLEAN-UP block (section 0) before starting. For D and E, open two Query Tool tabs on `clinic_db` and follow the SESSION 1 / SESSION 2 labels. Run the restore line at the end of E.
