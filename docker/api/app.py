import os
import socket
import requests

from flask import Flask, jsonify

app = Flask(__name__)

USERS_SERVICE_URL = os.getenv(
    "USERS_SERVICE_URL",
    "http://sidiqi-devops-users:5001"
)

ORDERS_SERVICE_URL = os.getenv(
    "ORDERS_SERVICE_URL",
    "http://sidiqi-devops-orders:5002"
)


@app.route("/")
def home():
    return jsonify(
        service="api",
        message="Sidiqi DevOps Microservice API",
        hostname=socket.gethostname()
    )


@app.route("/health")
@app.route("/api/health")
def health():
    return jsonify({
        "service": "api",
        "status": "healthy"
    })

@app.route("/api/info")
def info():
    return jsonify(
        service="api",
        version="1.1",
        architecture="microservice"
    )


@app.route("/api/users")
def users():
    try:
        response = requests.get(
            f"{USERS_SERVICE_URL}/users",
            timeout=3
        )
        response.raise_for_status()
        return jsonify(response.json())
    except requests.RequestException as error:
        return jsonify(
            service="api",
            downstream="users",
            status="error",
            error=str(error)
        ), 503


@app.route("/api/orders")
def orders():
    try:
        response = requests.get(
            f"{ORDERS_SERVICE_URL}/orders",
            timeout=3
        )
        response.raise_for_status()
        return jsonify(response.json())
    except requests.RequestException as error:
        return jsonify(
            service="api",
            downstream="orders",
            status="error",
            error=str(error)
        ), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
