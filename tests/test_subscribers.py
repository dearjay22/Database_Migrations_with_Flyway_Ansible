import os
import pymysql
import uuid
import time
import pytest

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_USER = os.getenv("DB_USER", "sub_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "sub_pass")
DB_NAME = os.getenv("DB_NAME", "subscriptions")

def get_connection():
    """Get database connection with retry logic"""
    max_retries = 5
    for attempt in range(max_retries):
        try:
            connection = pymysql.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                cursorclass=pymysql.cursors.DictCursor,
                autocommit=True
            )
            return connection
        except pymysql.Error as e:
            if attempt == max_retries - 1:
                raise e
            time.sleep(2)
    return None

def test_database_connection():
    """Test that we can connect to the database"""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 as test")
            result = cur.fetchone()
            assert result["test"] == 1

def test_table_exists():
    """Test that subscribers table exists"""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*) as count 
                FROM information_schema.tables 
                WHERE table_schema = %s AND table_name = 'subscribers'
            """, (DB_NAME,))
            result = cur.fetchone()
            assert result["count"] == 1

def test_create_read_update_delete():
    """Test CRUD operations"""
    email = f"test_{uuid.uuid4().hex}@example.com"
    name = "Test User"
    
    # CREATE
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO subscribers (email, name) VALUES (%s, %s)",
                (email, name)
            )
            subscriber_id = cur.lastrowid
            assert subscriber_id is not None
            print(f"Created subscriber with ID: {subscriber_id}")

    # READ
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM subscribers WHERE id = %s", (subscriber_id,))
            row = cur.fetchone()
            assert row is not None
            assert row["email"] == email
            assert row["name"] == name
            print(f"Read subscriber: {row}")

    # UPDATE
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE subscribers SET name = %s WHERE id = %s",
                ("Updated Name", subscriber_id)
            )
            cur.execute("SELECT name FROM subscribers WHERE id = %s", (subscriber_id,))
            updated_row = cur.fetchone()
            assert updated_row["name"] == "Updated Name"
            print(f"Updated subscriber name to: {updated_row['name']}")

    # DELETE
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM subscribers WHERE id = %s", (subscriber_id,))
            cur.execute("SELECT COUNT(*) as count FROM subscribers WHERE id = %s", (subscriber_id,))
            result = cur.fetchone()
            assert result["count"] == 0
            print("Successfully deleted subscriber")

def test_unique_email_constraint():
    """Test that email uniqueness constraint works"""
    email = f"unique_{uuid.uuid4().hex}@example.com"
    
    with get_connection() as conn:
        with conn.cursor() as cur:
            # First insert should work
            cur.execute(
                "INSERT INTO subscribers (email, name) VALUES (%s, %s)",
                (email, "First User")
            )
            first_id = cur.lastrowid
            
            # Second insert with same email should fail
            try:
                cur.execute(
                    "INSERT INTO subscribers (email, name) VALUES (%s, %s)",
                    (email, "Second User")
                )
                assert False, "Should have failed due to unique constraint"
            except pymysql.Error:
                # Expected - unique constraint violation
                pass
            
            # Cleanup
            cur.execute("DELETE FROM subscribers WHERE id = %s", (first_id,))