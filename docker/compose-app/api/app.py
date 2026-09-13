import os

import requests
from flask import Flask, jsonify

app = Flask(__name__)

USERS_SERVICE_URL = os.getenv(
    "USERS_SERVICE_URL",
    "http://users:5001"
)

ORDERS_SERVICE_URL = os.getenv(
    "ORDERS_SERVICE_URL",
    "http://orders:5002"
)


@app.route("/")
def home():
    return jsonify({
        "service": "compose-api",
        "message": "Compose API service is running"
    })


@app.route("/health")
@app.route("/api/health")
def health():
    return jsonify({
        "service": "compose-api",
        "status": "healthy"
    })


@app.route("/api/users")
def users():
    try:
        response = requests.get(
            f"{USERS_SERVICE_URL}/users",
            timeout=3
        )
        response.raise_for_status()
        return jsonify(response.json())
    except requests.RequestException as exc:
        return jsonify({
            "service": "compose-api",
            "dependency": "users",
            "status": "unavailable",
            "error": str(exc)
        }), 503


@app.route("/api/orders")
def orders():
    try:
        response = requests.get(
            f"{ORDERS_SERVICE_URL}/orders",
            timeout=3
        )
        response.raise_for_status()
        return jsonify(response.json())
    except requests.RequestException as exc:
        return jsonify({
            "service": "compose-api",
            "dependency": "orders",
            "status": "unavailable",
            "error": str(exc)
        }), 503
