import os
import requests
from flask import Flask, request, render_template_string

app = Flask(__name__)

# DNS de l'ALB INTERNE (injecte via user_data)
APP_API_URL = "http://" + os.environ["INTERNAL_ALB_DNS"] + "/api/signup"

BASE_CSS = """
  *{box-sizing:border-box;}
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
       font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
       background:linear-gradient(135deg,#6366f1 0%,#8b5cf6 50%,#a855f7 100%);padding:20px;color:#111827;}
  .card{background:#fff;border-radius:18px;box-shadow:0 24px 60px rgba(31,41,55,.28);
        padding:42px 38px;width:100%;max-width:430px;animation:pop .25s ease;}
  @keyframes pop{from{opacity:0;transform:translateY(10px);}to{opacity:1;transform:none;}}
  .brand{font-size:.72rem;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:#8b5cf6;margin-bottom:14px;}
  h1{margin:0 0 6px;font-size:1.55rem;font-weight:700;}
  .sub{margin:0 0 26px;color:#6b7280;font-size:.94rem;}
  .field{margin-bottom:16px;}
  label{display:block;font-size:.82rem;font-weight:600;color:#374151;margin-bottom:6px;}
  input{width:100%;padding:12px 14px;border:1.5px solid #e5e7eb;border-radius:11px;font-size:1rem;
        transition:border-color .15s,box-shadow .15s;background:#f9fafb;}
  input:focus{outline:none;border-color:#6366f1;background:#fff;box-shadow:0 0 0 4px rgba(99,102,241,.15);}
  button{width:100%;margin-top:8px;padding:13px;border:none;border-radius:11px;cursor:pointer;
         font-size:1rem;font-weight:600;color:#fff;background:#6366f1;transition:background .15s,transform .05s;}
  button:hover{background:#4f46e5;}
  button:active{transform:scale(.99);}
  .foot{margin-top:22px;text-align:center;font-size:.76rem;color:#9ca3af;}
  .icon{width:66px;height:66px;border-radius:50%;display:flex;align-items:center;justify-content:center;
        margin:0 auto 20px;font-size:34px;font-weight:700;}
  .ok .icon{background:#dcfce7;color:#16a34a;} .ko .icon{background:#fee2e2;color:#dc2626;}
  .center{text-align:center;}
  .msg{color:#6b7280;font-size:.98rem;margin:0 0 26px;}
  .link{display:inline-block;padding:11px 22px;border-radius:11px;text-decoration:none;
        font-weight:600;color:#4f46e5;background:#eef2ff;transition:background .15s;}
  .link:hover{background:#e0e7ff;}
"""

FORM = """
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Inscription</title>
<style>""" + BASE_CSS + """</style></head><body>
  <div class="card">
    <div class="brand">Gomeka &middot; Espace membre</div>
    <h1>Creer un compte</h1>
    <p class="sub">Rejoignez la plateforme en quelques secondes.</p>
    <form method="post" action="/signup">
      <div class="field"><label>Nom complet</label>
        <input name="full_name" placeholder="Jean Dupont"></div>
      <div class="field"><label>Adresse email</label>
        <input name="email" type="email" placeholder="jean.dupont@exemple.com" required></div>
      <div class="field"><label>Mot de passe</label>
        <input name="password" type="password" placeholder="........" required></div>
      <button type="submit">S'inscrire</button>
    </form>
    <p class="foot">TD3 &middot; Architecture 3-tiers AWS &middot; Groupe Dany-David</p>
  </div>
</body></html>
"""

RESULT = """
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Inscription</title>
<style>""" + BASE_CSS + """</style></head><body>
  <div class="card center {% if ok %}ok{% else %}ko{% endif %}">
    {% if ok %}<div class="icon">&#10003;</div>{% else %}<div class="icon">&#10007;</div>{% endif %}
    <h1>{% if ok %}Compte cree{% else %}Oups...{% endif %}</h1>
    <p class="msg">{{ msg }}</p>
    <a class="link" href="/">Retour au formulaire</a>
  </div>
</body></html>
"""


@app.get("/health")
def health():
    return "ok", 200


@app.get("/")
def form():
    return render_template_string(FORM)


@app.post("/signup")
def signup():
    full_name = request.form.get("full_name", "")
    email = request.form.get("email", "")
    password = request.form.get("password", "")

    try:
        r = requests.post(
            APP_API_URL,
            json={"full_name": full_name, "email": email, "password": password},
            timeout=5,
        )
    except requests.RequestException as e:
        return render_template_string(RESULT, ok=False, msg="Service indisponible : " + str(e)), 502

    if r.status_code == 201:
        return render_template_string(RESULT, ok=True, msg="Bienvenue " + (full_name or email) + " ! Votre compte a bien ete cree.")
    elif r.status_code == 409:
        return render_template_string(RESULT, ok=False, msg="Cet email est deja inscrit."), 409
    elif r.status_code == 400:
        return render_template_string(RESULT, ok=False, msg="Donnees invalides, verifiez vos informations."), 400
    else:
        return render_template_string(RESULT, ok=False, msg="Erreur serveur (%d), reessayez plus tard." % r.status_code), 502


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
