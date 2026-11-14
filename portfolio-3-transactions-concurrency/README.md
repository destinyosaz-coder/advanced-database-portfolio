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

## 3. Analysis

**1. Atomicity (Exercise C).** ## 3. Analysis

**1. Atomicity (Exercise C).** Atomicity means a transaction is all or nothing. In Exercise C, I inserted one valid patient and then a second patient with an invalid gender. The second insert broke the CHECK constraint, so I rolled back, and the count of "Atomic" patients was 0. Even the valid insert was undone. Exercise A shows the same idea from the good side: cancelling the old appointment and creating the new one either both happen or neither does.

**2. Why session 2 waited (Exercise D).** ## 3. Analysis

**1. Atomicity (Exercise C).** Atomicity means a transaction is all or nothing. In Exercise C, I inserted one valid patient and then a second patient with an invalid gender. The second insert broke the CHECK constraint, so I rolled back, and the count of "Atomic" patients was 0. Even the valid insert was undone. Exercise A shows the same idea from the good side: cancelling the old appointment and creating the new one either both happen or neither does.

**2. Why session 2 waited (Exercise D).** Session 1 had inserted the 10:00 booking for doctor 2 but had not committed it, so the outcome was still unknown. If session 1 rolled back, the slot would be free, and if it committed, the slot would be taken. PostgreSQL therefore made session 2 wait. When session 1 committed, session 2 failed with a duplicate key error on `uq_doctor_slot`.

**3. Without the UNIQUE constraint.** Both receptionists could book the doctor at the same time, which would create double bookings. Checking in application code first for example asking "is the slot free?" is not safe. Both sessions might check at the moment. Both might see the slot free. Both might insert a booking. The database constraint closes that gap.

**4. READ COMMITTED vs REPEATABLE READ (Exercise E).** With READ COMMITTED, each statement sees the newest committed data, so when session 2 raised the price and committed, my second read in session 1 showed the new price. This is a non-repeatable read. With REPEATABLE READ, session 1 kept seeing the data just as it was when the transaction started, so the price stayed the same until I committed and read again.

**5. My choice for the clinic.** I would use READ COMMITTED for work such as booking, because the UNIQUE constraint already helps prevents double bookings, and it results in fewer conflicts. I would use REPEATABLE READ for reports that read several tables and need one consistent picture, such as a monthly summary. The trade-off is that stricter isolation gives more consistency but can cause more waiting or failed transactions that have to be retried.`.

**3. Without the UNIQUE constraint.** Both receptionists would have been able to book the same doctor at the same time, giving a double booking. Checking in application code first ("is the slot free?") is not safe, because both sessions can check at the same moment, both see it free, and both insert. The database constraint closes that gap.

**4. READ COMMITTED vs REPEATABLE READ (Exercise E).** With READ COMMITTED, each statement sees the latest committed data, so when session 2 raised the price and committed, my second read in session 1 showed the new price. This is a non-repeatable read. With REPEATABLE READ, session 1 kept seeing the data as it was when the transaction started, so the price stayed the same until I committed and read again.

**5. My choice for the clinic.** I would use READ COMMITTED for everyday work such as booking, because the UNIQUE constraint already prevents double bookings, and it causes fewer conflicts. I would use REPEATABLE READ for reports that read several tables and need one consistent picture, such as a monthly summary. The trade-off is that stricter isolation gives more consistency but can cause more waiting or failed transactions that have to be retried.
**2. Why session 2 waited (Exercise D).** Session 1 had inserted the 10:00 booking for doctor 2 but had not committed it, so the outcome was still unknown. If session 1 rolled back, the slot would be free, and if it committed, the slot would be taken. PostgreSQL therefore made session 2 wait. When session 1 committed, session 2 failed with a duplicate key error on `uq_doctor_slot`.

**3. Without the UNIQUE constraint.** Both receptionists would have been able to book the same doctor at the same time, giving a double booking. Checking in application code first ("is the slot free?") is not safe, because both sessions can check at the same moment, both see it free, and both insert. The database constraint closes that gap.

**4. READ COMMITTED vs REPEATABLE READ (Exercise E).** With READ COMMITTED, each statement sees the latest committed data, so when session 2 raised the price and committed, my second read in session 1 showed the new price. This is a non-repeatable read. With REPEATABLE READ, session 1 kept seeing the data as it was when the transaction started, so the price stayed the same until I committed and read again.

**5. My choice for the clinic.** I would use READ COMMITTED for everyday work such as booking, because the UNIQUE constraint already prevents double bookings, and it causes fewer conflicts. I would use REPEATABLE READ for reports that read several tables and need one consistent picture, such as a monthly summary. The trade-off is that stricter isolation gives more consistency but can cause more waiting or failed transactions that have to be retried.

## 4. Evidence checklist
- [ ] A: result after COMMIT
- [ ] B: price before, inside the transaction, after ROLLBACK
- [ ] C: the error message and the final count of 0
- [ ] D: session 2 waiting, then the duplicate key error
- [ ] E: both isolation levels, with the two reads side by side

## 5. How to run
Use `transactions.sql` from the top. Run the CLEAN-UP block (section 0) before starting. For D and E, open two Query Tool tabs on `clinic_db` and follow the SESSION 1 / SESSION 2 labels. Run the restore line at the end of E.
