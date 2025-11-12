
-- V1__create_subscribers.sql
CREATE TABLE IF NOT EXISTS subscribers (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL UNIQUE
);
