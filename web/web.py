import os
import requests
from flask import Flask, request, render_template_string

app = Flask(__name__)

# DNS de l'ALB INTERNE (injecte via user_data)
APP_API_URL = "http://" + os.environ["INTERNAL_ALB_DNS"] + "/api/signup"

FORM = """
<!doctype html><title>Inscription</title>
<h1>Creer un compte</h1>
<form method="post" action="/signup">
  <input name="full_name" placeholder="Nom complet"><br>
  <input name="email" type="email" placeholder="Email" required><br>
  <input name="password" type="password" placeholder="Mot de passe" required><br>
  <button type="submit">S'inscrire</button>
</form>
"""

RESULT = """
<!doctype html><title>Inscription</title>
<h1>{{ "Succes" if ok else "Echec" }}</h1>
<p>{{ msg }}</p>
<a href="/">Retour</a>
"""


@app.get("/health")
def health():
    return "ok", 200


@app.get("/")
def form():
    return render_template_string(FORM)


@app.post("/signup")
def signup():
    # TODO 1 -> recuperer les champs du formulaire
    full_name = request.form.get("full_name", "")
    email = request.form.get("email", "")
    password = request.form.get("password", "")

    # TODO 2 -> POST JSON vers l'API interne (avec timeout)
    try:
        r = requests.post(
            APP_API_URL,
            json={"full_name": full_name, "email": email, "password": password},
            timeout=5,
        )
    except requests.RequestException as e:
        return render_template_string(RESULT, ok=False, msg="Service indisponible : " + str(e)), 502

    # TODO 3 -> message selon le code retour de l'API
    if r.status_code == 201:
        return render_template_string(RESULT, ok=True, msg="Compte cree pour " + email)
    elif r.status_code == 409:
        return render_template_string(RESULT, ok=False, msg="Cet email est deja inscrit."), 409
    elif r.status_code == 400:
        return render_template_string(RESULT, ok=False, msg="Donnees invalides."), 400
    else:
        return render_template_string(RESULT, ok=False, msg="Erreur serveur (%d)." % r.status_code), 502


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
