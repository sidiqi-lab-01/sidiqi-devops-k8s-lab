from flask import Flask, jsonify
import socket

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify(
        service="users",
        message="Sidiqi DevOps Users Service",
        hostname=socket.gethostname()
    )


@app.route("/health")
def health():
    return jsonify(
        service="users",
        status="healthy"
    )


@app.route("/users")
def users():
    return jsonify(
        service="users",
        users=[
            {"id": 1, "name": "Alice"},
            {"id": 2, "name": "Bob"},
            {"id": 3, "name": "Charlie"}
        ]
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
