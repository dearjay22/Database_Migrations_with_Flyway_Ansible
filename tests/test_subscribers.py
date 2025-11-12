import os
import uuid
import pymysql
import pytest

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_USER = os.getenv("DB_USER", "root")
DB_PWD = os.getenv("DB_PASSWORD", "rootpass")
DB_NAME = os.getenv("DB_NAME", "subscriptions")


def connect():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PWD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
    )


def test_create_subscriber():
    email = f"{uuid.uuid4()}@example.com"
    name = "Alice"
    with connect() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO subscribers (email, name) VALUES (%s, %s)", (email, name))
        sub_id = cur.lastrowid
        assert sub_id is not None


def test_read_subscriber():
    email = f"{uuid.uuid4()}@example.com"
    name = "Bob"
    with connect() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO subscribers (email, name) VALUES (%s, %s)", (email, name))
        sub_id = cur.lastrowid
        cur.execute("SELECT * FROM subscribers WHERE id = %s", (sub_id,))
        row = cur.fetchone()
        assert row is not None
        assert row["email"] == email
        assert row["name"] == name


def test_update_subscriber():
    email = f"{uuid.uuid4()}@example.com"
    name = "Charlie"
    new_name = "Charlie Updated"
    with connect() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO subscribers (email, name) VALUES (%s, %s)", (email, name))
        sub_id = cur.lastrowid
        cur.execute("UPDATE subscribers SET name = %s WHERE id = %s", (new_name, sub_id))
        cur.execute("SELECT name FROM subscribers WHERE id = %s", (sub_id,))
        row = cur.fetchone()
        assert row["name"] == new_name


def test_delete_subscriber():
    email = f"{uuid.uuid4()}@example.com"
    name = "Jay"
    with connect() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO subscribers (email, name) VALUES (%s, %s)", (email, name))
        sub_id = cur.lastrowid
        cur.execute("DELETE FROM subscribers WHERE id = %s", (sub_id,))
        cur.execute("SELECT COUNT(*) AS n FROM subscribers WHERE id = %s", (sub_id,))
        count = cur.fetchone()["n"]
        assert count == 0
