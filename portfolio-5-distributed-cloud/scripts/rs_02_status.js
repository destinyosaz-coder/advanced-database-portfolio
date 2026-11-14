// Shows who is PRIMARY and who is SECONDARY.
// Run:  mongosh --port 27018 --file rs_02_status.js   (any port works)
rs.status().members.forEach(m => print(m.name + "  ->  " + m.stateStr));
