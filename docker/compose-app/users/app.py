from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({
        "service": "compose-users",
        "message": "Users service is running"
    })


@app.route("/health")
def health():
    return jsonify({
        "service": "compose-users",
        "status": "healthy"
    })


@app.route("/users")
def users():
    return jsonify({
        "service": "compose-users",
        "users": [
            {"id": 1, "name": "Sidiqi1"},
            {"id": 2, "name": "Sidiqi2"},
            {"id": 3, "name": "Sidiqi3"}
        ]
    })
