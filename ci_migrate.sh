#!/bin/bash
set -e

echo "Ensuring MySQL container is running..."
docker ps --filter "name=a4-mysql" --filter "status=running" --format "{{.Names}}" | grep -q a4-mysql \
  || docker run -d --name a4-mysql -e MYSQL_ROOT_PASSWORD=rootpass -e MYSQL_DATABASE=subscriptions -p 3306:3306 mysql:8

echo "Waiting for MySQL to be ready..."
until docker exec a4-mysql mysqladmin ping -h "localhost" -prootpass --silent; do
  sleep 3
done
echo "MySQL is ready!"

echo "Creating DB user with default authentication..."
docker exec -i a4-mysql mysql -uroot -prootpass -e "
DROP USER IF EXISTS 'sub_user'@'%';
CREATE USER 'sub_user'@'%' IDENTIFIED BY 'sub_pass';
GRANT ALL PRIVILEGES ON subscriptions.* TO 'sub_user'@'%';
FLUSH PRIVILEGES;"

echo "Running initial Flyway migrations..."
docker run --rm -v $(pwd)/flyway:/flyway/sql --network host flyway/flyway:10 \
  -url=jdbc:mysql://localhost:3306/subscriptions \
  -user=root \
  -password=rootpass \
  -locations=filesystem:/flyway/migrations_initial \
  migrate

echo "Running incremental Flyway migrations..."
docker run --rm -v $(pwd)/flyway:/flyway/sql --network host flyway/flyway:10 \
  -url=jdbc:mysql://localhost:3306/subscriptions \
  -user=root \
  -password=rootpass \
  -locations=filesystem:/flyway/migrations_incremental \
  migrate

echo "Flyway migrations completed!"
