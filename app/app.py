import os
import hashlib
import secrets
import psycopg2
from flask import Flask, request, jsonify

app = Flask(__name__)

DB_CONFIG = {
    "host": os.environ["DB_HOST"],      # endpoint RDS (injecte via user_data)
    "dbname": os.environ["DB_NAME"],
    "user": os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
    "port": 5432,
}


def get_conn():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True
    return conn


def init_db():
    """Cree la table users au premier demarrage (idempotent)."""
    try:
        conn = get_conn()
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id            SERIAL PRIMARY KEY,
                    email         VARCHAR(255) NOT NULL UNIQUE,
                    password_hash VARCHAR(255) NOT NULL,
                    full_name     VARCHAR(255),
                    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """
            )
        conn.close()
    except Exception as e:
        print("init_db error:", e)


def hash_password(password):
    # Hachage avec sel (jamais de mot de passe en clair). bcrypt serait mieux en prod.
    salt = secrets.token_hex(16)
    digest = hashlib.sha256((salt + password).encode("utf-8")).hexdigest()
    return salt + ":" + digest


@app.get("/health")  # utilise par le health check de l'ALB (ne touche pas la base)
def health():
    return "ok", 200


@app.post("/api/signup")
def signup():
    data = request.get_json(force=True)
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""
    full_name = (data.get("full_name") or "").strip()

    # TODO 1 -> validation
    if not email or "@" not in email or "." not in email.split("@")[-1]:
        return jsonify({"error": "email invalide"}), 400
    if not password:
        return jsonify({"error": "mot de passe requis"}), 400

    # TODO 2 -> hachage
    password_hash = hash_password(password)

    # TODO 3 -> INSERT parametre (anti-injection SQL), 409 si email deja pris
    try:
        conn = get_conn()
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO users (email, password_hash, full_name) VALUES (%s, %s, %s)",
                (email, password_hash, full_name),
            )
        conn.close()
    except psycopg2.IntegrityError:
        return jsonify({"error": "email deja inscrit"}), 409
    except Exception as e:
        return jsonify({"error": "erreur serveur", "detail": str(e)}), 500

    return jsonify({"status": "created", "email": email}), 201


init_db()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
