// Run once:  mongosh --port 27018 --file rs_01_initiate.js
rs.initiate({
  _id: "clinicRS",
  members: [
    { _id: 0, host: "localhost:27018" },
    { _id: 1, host: "localhost:27019" },
    { _id: 2, host: "localhost:27020" }
  ]
});
sleep(8000);   // wait for the first election
rs.status().members.forEach(m => print(m.name + "  ->  " + m.stateStr));
