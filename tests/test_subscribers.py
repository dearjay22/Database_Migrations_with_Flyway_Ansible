import os
import uuid
import pymysql

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


def test_create_read_update_delete():
    """Test full CRUD lifecycle for a subscriber."""
    email = f"{uuid.uuid4()}@example.com"
    name = "Alice"

    # CREATE
    with connect() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO subscribers(email, name) VALUES(%s, %s)", (email, name))
        sub_id = cur.lastrowid
        assert sub_id, "INSERT failed, no ID returned"

    # READ
    with connect() as conn, conn.cursor() as cur:
        cur.execute("SELECT * FROM subscribers WHERE id=%s", (sub_id,))
        row = cur.fetchone()
        assert row, f"SELECT failed, no row found for id={sub_id}"
        assert row["email"] == email, "Email does not match inserted value"

    # UPDATE
    with connect() as conn, conn.cursor() as cur:
        cur.execute("UPDATE subscribers SET name=%s WHERE id=%s", ("Alice Updated", sub_id))
        cur.execute("SELECT name FROM subscribers WHERE id=%s", (sub_id,))
        updated_name = cur.fetchone()["name"]
        assert updated_name == "Alice Updated", f"UPDATE failed, name={updated_name}"

    # DELETE
    with connect() as conn, conn.cursor() as cur:
        cur.execute("DELETE FROM subscribers WHERE id=%s", (sub_id,))
        cur.execute("SELECT COUNT(*) AS n FROM subscribers WHERE id=%s", (sub_id,))
        assert cur.fetchone()["n"] == 0, "DELETE failed, record still exists"
