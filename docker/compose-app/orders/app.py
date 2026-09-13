import os

from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)


DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "ordersdb")
DB_USER = os.getenv("DB_USER", "ordersuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")


def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )


@app.route("/")
def home():
    return jsonify({
        "service": "compose-orders",
        "message": "Orders service is running"
    })


@app.route("/health")
def health():
    try:
        conn = get_db_connection()
        conn.close()

        return jsonify({
            "service": "compose-orders",
            "status": "healthy",
            "database": "connected"
        })
    except Exception as exc:
        return jsonify({
            "service": "compose-orders",
            "status": "unhealthy",
            "database": "unavailable",
            "error": str(exc)
        }), 503


@app.route("/orders")
def orders():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT id, user_id, item, status
            FROM orders
            ORDER BY id
        """)

        rows = cursor.fetchall()

        cursor.close()
        conn.close()

        return jsonify({
            "service": "compose-orders",
            "orders": [
                {
                    "id": row[0],
                    "user_id": row[1],
                    "item": row[2],
                    "status": row[3]
                }
                for row in rows
            ]
        })

    except Exception as exc:
        return jsonify({
            "service": "compose-orders",
            "error": str(exc)
        }), 503
