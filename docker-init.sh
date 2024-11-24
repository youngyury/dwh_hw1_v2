echo "Clearing data"
rm -rf ./data/*
rm -rf ./data-slave/*
docker-compose down

docker-compose up -d  postgres_master

echo "Starting postgres_master node..."
sleep 5  # Waits for master note start complete

echo "Prepare replica config..."
docker exec -it postgres_master sh /etc/postgresql/init-script/init.sh
echo "Restart master node"
docker-compose restart postgres_master
sleep 5

echo "Starting slave node..."
docker-compose up -d  postgres_slave
sleep 5  # Waits for note start complete

echo "Starting dwh node..."
docker-compose up -d  postgres_dwh
sleep 5  # Waits for node start complete

echo "Starting zookeeper node..."
docker-compose up -d  zookeeper
sleep 5  # Waits for node start complete

echo "Starting kafka node..."
docker-compose up -d  broker
sleep 5  # Waits for node start complete

echo "Starting debezium node..."
docker-compose up -d  debezium
sleep 5  # Waits for node start complete

echo "Starting debezium-ui node..."
docker-compose up -d  debezium-ui
sleep 5  # Waits for node start complete

echo "Starting schema-registry node..."
docker-compose up -d  schema-registry
sleep 5  # Waits for node start complete

echo "Starting rest-proxy node..."
docker-compose up -d  rest-proxy
sleep 5  # Waits for node start complete

curl -X POST --location "http://localhost:8083/connectors" -H "Content-Type: application/json" -H "Accept: application/json" -d @connector.json

echo "Starting dmp-service node..."
docker-compose up --build -d dmp-service
sleep 5  # Waits for node start complete

echo "Done!"
