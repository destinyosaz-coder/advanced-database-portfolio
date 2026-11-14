# Portfolio 5: Distributed and Cloud Database Exercise

**Course:** MIT 8103 Advanced Database Systems | **Student:** Destiny Osazuwa (301908420)
**Case study:** Lagos Community Clinic | **Technology:** PostgreSQL 18 (partitioning), MongoDB (replica set)

## 1. What this portfolio shows
| Part | Concept | Technology | Evidence |
|---|---|---|---|
| A | Partitioning (data split by date) | PostgreSQL | Rows per partition, pruned query plan |
| B | Replication, availability and failover | MongoDB replica set, 3 nodes | Status before and after failover, data on all nodes |
| C | Sharding, consistency and cloud deployment (design) | Written discussion | This README |

## 2. Part A: Partitioning (`partitioning.sql`)
The `appointment` table is the biggest in the clinic. `appointment_part` splits it into quarterly partitions by `appointment_time`. A query for one month reads only the matching partition (**partition pruning**), instead of scanning everything.

Your results (fill in from your screenshots):
| Query | Plan | Execution time |
|---|---|---|
| Partitioned table, May 2024 | Scans only `appt_2024_q2` | ___ ms |
| Ordinary table, May 2024 | Scans the full table or index | ___ ms |

## 3. Part B: Replication and failover (`scripts/`)
A **replica set** keeps the same data on three servers. One is the **primary** (accepts writes); the other two are **secondaries** that copy it. If the primary fails, the others **elect** a new primary automatically.

| Step | Script | What it proves |
|---|---|---|
| Start 3 nodes | `00_start_replica_set.sh` | Three servers on ports 27018 to 27020 |
| Form the set | `rs_01_initiate.js` | One PRIMARY, two SECONDARY |
| Write data | `rs_03_write.js` | Write acknowledged by a majority of nodes |
| Read from each node | `rs_04_read_secondary.js` | The same record exists on every node (replication) |
| Failover | `rs_05_failover.js`, then `rs_02_status.js` | A different node becomes PRIMARY |
| Write again | `rs_03_write.js` | The system stays available after failover |

## 4. Part C: Design discussion (write in your own words)
Write 3 to 5 sentences for each heading. Use the prompts as a guide, not as text to copy.

**4.1 Replication and availability.** What happened to the clinic's service when the primary stepped down? Why does a clinic need this (think: doctors cannot wait for a server to be repaired)?

**4.2 Consistency.** In `rs_03_write.js` the write waited for a *majority* of nodes. What does that protect against? What is the trade-off in speed? Compare with reading from a secondary, which can lag slightly behind (eventual consistency).

**4.3 CAP theorem.** In one paragraph, explain Consistency, Availability and Partition tolerance. During a network split, which would a clinic's *appointment booking* choose and why (avoiding double-booking), and which could a *patient history viewer* relax?

**4.4 Sharding.** Sharding spreads data across servers. Propose a shard key for the clinic. Compare:
- `patientId` (hashed): spreads load evenly, and one patient's records stay together.
- clinic branch or region: keeps data close to users, but can create hot spots.
Which do you choose, and why?

**4.5 Cloud deployment.** Describe how you would run this in the cloud, for example MongoDB Atlas for the patient-history database and a managed PostgreSQL service (such as Amazon RDS or Azure Database for PostgreSQL) for bookings. Mention backups, security (patient data is sensitive) and cost.

## 5. Evidence checklist
- [ ] A: rows per partition
- [ ] A: pruned plan versus ordinary plan
- [ ] B: three nodes started
- [ ] B: status after `rs_01_initiate.js` (1 PRIMARY, 2 SECONDARY)
- [ ] B: write result and reads on all three ports
- [ ] B: status after failover (new PRIMARY)

## 6. References (add the ones you actually used)
- PostgreSQL Documentation: Table Partitioning.
- MongoDB Manual: Replication; Sharding.
