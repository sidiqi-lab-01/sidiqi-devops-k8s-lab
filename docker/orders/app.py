from flask import Flask, jsonify
import socket

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify(
        service="orders",
        message="Sidiqi DevOps Orders Service",
        hostname=socket.gethostname()
    )


@app.route("/health")
def health():
    return jsonify(
        service="orders",
        status="healthy"
    )


@app.route("/orders")
def orders():
    return jsonify(
        service="orders",
        orders=[
            {"id": 101, "user_id": 1, "item": "Laptop", "status": "shipped"},
            {"id": 102, "user_id": 2, "item": "Monitor", "status": "processing"},
            {"id": 103, "user_id": 3, "item": "Keyboard", "status": "delivered"}
        ]
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)
