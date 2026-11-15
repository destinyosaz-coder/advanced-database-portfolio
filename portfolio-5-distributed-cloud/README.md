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
The `appointment` table is the biggest table in the clinic. I created `appointment_part`, which splits it into quarterly partitions by `appointment_time`, plus a default partition for dates outside 2024. PostgreSQL routed all 100,002 rows automatically: 29,120 in Q1, 29,120 in Q2, 29,440 in Q3, 12,320 in Q4, and 2 in `appt_other` (the 2030 test bookings from Portfolio 3).

| Query (May 2024 count) | Plan | Execution time |
|---|---|---|
| Partitioned table | Seq Scan on `appt_2024_q2` only (19,200 rows removed by the filter) | 13.207 ms |
| Ordinary table | Index Only Scan on `idx_appt_status_time` | 10.691 ms |

**Analysis.** The plan on the partitioned table touched only the Q2 partition and ignored the other four. This is called partition pruning, and it means that the database reads about 29,000 rows instead of 100,000. However, the partitioned query was not faster here (13.207 ms against 10.691 ms), because the ordinary table already has the index `idx_appt_status_time` from Portfolio 2, which lets PostgreSQL answer the count straight from the index, while my partitions have no index of their own. Partitioning would help more on a very large table, because old partitions can be archived or dropped quickly and each partition is smaller to scan and maintain. It is also the same idea as sharding, but inside one server.

## 3. Part B: Replication and failover (`scripts/`)
A **replica set** keeps the same data on three servers. One is the **primary** (accepts writes); the other two are **secondaries** that copy it. If the primary fails, the others **elect** a new primary automatically.

**My results.** I started three MongoDB servers on ports 27018, 27019 and 27020 as the replica set `clinicRS`. After the first election, `27018` was the PRIMARY and the other two were SECONDARY. I wrote one visit record through the PRIMARY with a majority write concern, and reading from each node on its own port showed the same record on all three (1 record each), which confirms replication. I then made the PRIMARY step down. `27020` was elected as the new PRIMARY, `27018` became a SECONDARY, and a second write succeeded through the new PRIMARY (total records: 2), so the service stayed available.

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

**4.1 Replication and availability.** When I forced the primary (`27018`) to step down, the other two servers held an election and `27020` became the new primary within seconds. My next write succeeded without any change to my connection settings, because the replica-set connection string finds the current primary on its own. For a clinic, this matters because doctors and receptionists cannot wait for a failed server to be repaired. With three copies of the data, one server can fail and the clinic keeps working.

**4.2 Consistency.** My write used a "majority" write concern, which means it was only acknowledged after at least 2 of the 3 servers had it. This protects against losing a record if the primary fails right after the write. The trade-off is that the write is a little slower than waiting for one server only. Reading from a secondary can be slightly behind the primary, which is called eventual consistency. In my test all three nodes showed the new record, but under heavy load a secondary could briefly lag, so reads that must be fully up to date should go to the primary.

**4.3 CAP theorem.** The CAP theorem says that when a network split happens, a distributed database can keep either consistency (everyone sees the same data) or availability (every request gets an answer), but not both. For appointment booking, I would choose consistency: during a split it is better to refuse a booking than to give the same slot to two patients. For a patient-history viewer, I would accept availability, because showing slightly old history is better than showing nothing.

**4.4 Sharding.** Sharding spreads data over several servers using a shard key. For the clinic, I would use a hashed `patientId`. It spreads patients evenly, and all of one patient's records stay on the same shard, so the most common query, one patient's history, touches only one server. A branch or region key would keep data close to users, but a busy branch would become a hot spot. The weakness of my choice is that a query by doctor or by date has to ask all the shards.

**4.5 Cloud deployment.** I did not deploy to the cloud; this is a design. I would run the patient-history database on MongoDB Atlas, which provides replica sets and sharding as a managed service, and the booking database on a managed PostgreSQL service such as Amazon RDS or Azure Database for PostgreSQL. Patient data is sensitive, so I would turn on automated backups, encryption in transit and at rest, and strict access controls, in line with data protection law such as the Nigeria Data Protection Act 2023. The cost would grow with storage and traffic, so I would start small and scale up when needed.
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
