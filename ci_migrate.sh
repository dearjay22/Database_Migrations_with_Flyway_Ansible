#!/bin/bash
set -e

# Variables
MYSQL_CONTAINER_NAME="a4-mysql"
MYSQL_ROOT_PASSWORD="rootpass"
DB_NAME="subscriptions"
DB_USER="root"
DB_PASS="rootpass"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

# Paths
INITIAL_MIGRATIONS="./flyway/migrations_initial"
INCREMENTAL_MIGRATIONS="./flyway/migrations_incremental"

echo "Ensuring MySQL container is running..."
docker ps --filter "name=$MYSQL_CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q $MYSQL_CONTAINER_NAME \
  || docker run -d --name $MYSQL_CONTAINER_NAME \
        -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
        -e MYSQL_DATABASE=$DB_NAME \
        -p $MYSQL_PORT:3306 \
        mysql:8

echo "Waiting for MySQL to be ready..."
until docker exec $MYSQL_CONTAINER_NAME mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1" >/dev/null 2>&1; do
  sleep 3
done
echo "MySQL is ready!"

echo "Running initial Flyway migrations..."
docker run --rm \
  -v "$(pwd)/flyway/migrations_initial:/flyway/migrations_initial" \
  --network host \
  flyway/flyway:10 \
  -url=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/$DB_NAME?allowPublicKeyRetrieval=true&useSSL=false \
  -user=$DB_USER \
  -password=$DB_PASS \
  -locations=filesystem:/flyway/migrations_initial \
  migrate

echo "Running incremental Flyway migrations..."
docker run --rm \
  -v "$(pwd)/flyway/migrations_incremental:/flyway/migrations_incremental" \
  --network host \
  flyway/flyway:10 \
  -url=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/$DB_NAME?allowPublicKeyRetrieval=true&useSSL=false \
  -user=$DB_USER \
  -password=$DB_PASS \
  -locations=filesystem:/flyway/migrations_incremental \
  migrate

echo "All Flyway migrations completed!"
