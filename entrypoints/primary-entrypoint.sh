#!/bin/bash

# Start PostgreSQL in the background
docker-entrypoint.sh postgres &

# Wait for PostgreSQL to start up
while ! pg_isready -U postgres; do
  sleep 1
done

# create replicator user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'my_replicator_password';
    SELECT * FROM pg_create_physical_replication_slot('replication_slot_secondary1');
EOSQL

## Backup primary
pg_basebackup -D /var/lib/postgresql/data-slave -S replication_slot_secondary1 -X stream -P -U replicator -Fp -R

## initialize secondary
cp /etc/postgresql/init-script/configs/slave-config/* /var/lib/postgresql/data-slave
cp /etc/postgresql/init-script/config/pg_hba.conf /var/lib/postgresql/data

# Keep PostgreSQL running in the foreground
wait %1
