#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p evidence
start_container() {
  local name="$1"; shift
  if docker container inspect "$name" >/dev/null 2>&1; then
    docker start "$name" >/dev/null
  else
    docker run -d --name "$name" --label purpose=lab6-mospolytech "$@" >/dev/null
  fi
}
start_container lab6-postgres -p 127.0.0.1:55433:5432 \
  -e POSTGRES_USER=labuser -e POSTGRES_PASSWORD=lab6-study-only -e POSTGRES_DB=lab6_warehouse postgres:16
start_container lab6-mongo -p 127.0.0.1:27018:27017 mongo:7
start_container lab6-neo4j -p 127.0.0.1:7475:7474 -p 127.0.0.1:7688:7687 \
  -e NEO4J_AUTH=neo4j/lab6-study-only -e NEO4J_server_memory_heap_initial__size=256m \
  -e NEO4J_server_memory_heap_max__size=512m -e NEO4J_server_memory_pagecache_size=128m neo4j:5-community
for attempt in $(seq 1 60); do
  if docker exec lab6-postgres pg_isready -U labuser >/dev/null 2>&1 && \
     docker exec lab6-mongo mongosh --quiet --eval 'db.runCommand({ping:1})' >/dev/null 2>&1 && \
     docker exec lab6-neo4j cypher-shell -u neo4j -p lab6-study-only 'RETURN 1' >/dev/null 2>&1; then break; fi
  if [ "$attempt" = 60 ]; then echo 'Database startup timeout' >&2; exit 1; fi
  sleep 2
done
docker exec -i lab6-postgres psql -X -U labuser -d lab6_warehouse -v ON_ERROR_STOP=1 \
  < data-vault/01_schema_and_data.sql > evidence/postgres-build.txt
docker exec -i lab6-postgres psql -X -U labuser -d lab6_warehouse -v ON_ERROR_STOP=1 \
  < data-vault/02_verify.sql > evidence/postgres-verify.txt
docker exec -i lab6-mongo sh -c 'cat > /tmp/lab6.js && mongosh --quiet /tmp/lab6.js' \
  < mongodb/01_examples.js > evidence/mongodb-run.txt
for entry in 01_lecture 02_social_graph 03_queries; do
  docker exec -i lab6-neo4j cypher-shell -u neo4j -p lab6-study-only --format plain \
    < "neo4j/$entry.cypher" > "evidence/neo4j-$entry.txt"
done
docker exec lab6-postgres psql -X -U labuser -d lab6_warehouse -Atc 'SELECT version();' > evidence/versions.txt
docker exec lab6-mongo mongosh --quiet --eval 'db.version()' >> evidence/versions.txt
docker exec lab6-neo4j cypher-shell -u neo4j -p lab6-study-only \
  'CALL dbms.components() YIELD name,versions RETURN name,versions;' >> evidence/versions.txt
echo 'Готово: результаты находятся в evidence/. Neo4j Browser: http://localhost:7475/browser/'
