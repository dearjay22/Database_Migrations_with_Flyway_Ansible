#!/bin/bash
set -e

# DB credentials
DB_NAME="subscriptions"
DB_USER="root"
DB_PASS="rootpass"

echo "Waiting for MySQL service to be ready..."
until mysql -h host.docker.internal -P 3306 -u${DB_USER} -p${DB_PASS} -e "SELECT 1" >/dev/null 2>&1; do
    echo "MySQL is not ready yet... waiting 3s"
    sleep 3
done
echo "MySQL is ready!"

# Run initial Flyway migrations
echo "Running initial Flyway migrations..."
docker run --rm \
  -v $GITHUB_WORKSPACE/flyway/migrations_initial:/flyway/sql \
  flyway/flyway:10 \
  -url=jdbc:mysql://host.docker.internal:3306/${DB_NAME} \
  -user=${DB_USER} \
  -password=${DB_PASS} \
  -locations=filesystem:/flyway/sql \
  migrate

# Run incremental Flyway migrations
echo "Running incremental Flyway migrations..."
docker run --rm \
  -v $GITHUB_WORKSPACE/flyway/migrations_incremental:/flyway/sql \
  flyway/flyway:10 \
  -url=jdbc:mysql://host.docker.internal:3306/${DB_NAME} \
  -user=${DB_USER} \
  -password=${DB_PASS} \
  -locations=filesystem:/flyway/sql \
  migrate

echo "Flyway migrations completed!"
