#!/bin/bash
# Starts THREE MongoDB servers on ports 27018, 27019, 27020 (a replica set).
# Keep THIS window open while you work. Use a second Git Bash window for everything else.
# The normal MongoDB service on port 27017 is not touched.
MONGOD=$(ls -d "/c/Program Files/MongoDB/Server/"*/bin/mongod.exe | sort -V | tail -1)
echo "Using: $MONGOD"
mkdir -p ~/mongo-rs/node1 ~/mongo-rs/node2 ~/mongo-rs/node3
cd ~/mongo-rs
for i in 1 2 3; do
  port=$((27017 + i))
  "$MONGOD" --replSet clinicRS --port $port --dbpath node$i --bind_ip localhost --logpath node$i.log &
  echo "started node$i on port $port"
done
wait
