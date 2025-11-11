
-- V2__add_status_and_index.sql
ALTER TABLE subscribers ADD COLUMN status ENUM('active','inactive') DEFAULT 'active';
CREATE INDEX idx_created_at ON subscribers(created_at);
