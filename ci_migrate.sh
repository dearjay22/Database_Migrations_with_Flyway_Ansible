#!/bin/bash
set -e

# Variables
MYSQL_CONTAINER_NAME="a4-mysql"
MYSQL_ROOT_PASSWORD="rootpass"
DB_NAME="subscriptions"
DB_USER="sub_user"
DB_PASS="sub_pass"
MYSQL_PORT=3306

# Paths for migrations
INITIAL_MIGRATIONS="./flyway/migrations_initial"
INCREMENTAL_MIGRATIONS="./flyway/migrations_incremental"

echo "Ensuring MySQL container is running..."
docker ps --filter "name=${MYSQL_CONTAINER_NAME}" --filter "status=running" --format "{{.Names}}" | grep -q "${MYSQL_CONTAINER_NAME}" \
    || docker run -d --name ${MYSQL_CONTAINER_NAME} \
        -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
        -e MYSQL_DATABASE=${DB_NAME} \
        -p ${MYSQL_PORT}:3306 \
        mysql:8

echo "Waiting for MySQL to be ready..."
until docker exec ${MYSQL_CONTAINER_NAME} mysqladmin ping -h "localhost" -p${MYSQL_ROOT_PASSWORD} --silent; do
    sleep 3
done
echo "MySQL is ready!"

# Create DB user
echo "Creating DB user with default authentication..."
docker exec -i ${MYSQL_CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "
    DROP USER IF EXISTS '${DB_USER}'@'%';
    CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
    GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
    FLUSH PRIVILEGES;"

# Run initial Flyway migrations
echo "Running initial Flyway migrations..."
docker run --rm -v $(pwd)/flyway:/flyway/sql --network host flyway/flyway:10 \
    -url=jdbc:mysql://127.0.0.1:3306/${DB_NAME}?allowPublicKeyRetrieval=true&useSSL=false \
    -user=root -password=${MYSQL_ROOT_PASSWORD} \
    -locations=filesystem:/flyway/migrations_initial migrate

# Run incremental Flyway migrations
echo "Running incremental Flyway migrations..."
docker run --rm -v $(pwd)/flyway:/flyway/sql --network host flyway/flyway:10 \
    -url=jdbc:mysql://127.0.0.1:3306/${DB_NAME}?allowPublicKeyRetrieval=true&useSSL=false \
    -user=root -password=${MYSQL_ROOT_PASSWORD} \
    -locations=filesystem:/flyway/migrations_incremental migrate

echo "Flyway migrations completed!"
