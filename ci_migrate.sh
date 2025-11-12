#!/bin/bash
set -e

# Variables
FLYWAY_DIR="${GITHUB_WORKSPACE}/flyway"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
DB_NAME="subscriptions"
DB_USER="root"
DB_PASS="rootpass"

echo "Waiting for MySQL to be ready..."
until docker exec a4-mysql mysqladmin ping -h "$MYSQL_HOST" -p"$DB_PASS" --silent; do
  sleep 3
done

echo "Running initial Flyway migrations..."
docker run --rm -v $FLYWAY_DIR:/flyway/sql --network host flyway/flyway:10 \
  -url=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/$DB_NAME \
  -user=$DB_USER -password=$DB_PASS \
  -locations=filesystem:/flyway/migrations_initial migrate

echo "Running incremental Flyway migrations..."
docker run --rm -v $FLYWAY_DIR:/flyway/sql --network host flyway/flyway:10 \
  -url=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/$DB_NAME \
  -user=$DB_USER -password=$DB_PASS \
  -locations=filesystem:/flyway/migrations_incremental migrate

echo "Flyway migrations completed!"
