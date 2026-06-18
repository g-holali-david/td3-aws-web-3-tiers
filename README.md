# TD3 — Application web 3-tiers sur AWS (Terraform)

Mastère Cybersécurité 5ᵉ année · IPSSI — AWS Academy.

Déploiement complet d'une **architecture 3-tiers** (présentation / application / données)
en **Infrastructure as Code**. Inscription d'un utilisateur : du formulaire → API → RDS
PostgreSQL, via **deux Load Balancers** (un public, un interne).

```
Internet → ALB public → tier WEB (Flask form) → ALB interne → tier APP (API) → RDS PostgreSQL
                         (subnets privés)                       (subnets privés)   (Multi-AZ)
```

## Structure

| Fichier | Rôle |
|---------|------|
| `providers.tf` | provider AWS `~> 5.0` |
| `variables.tf` | région, AZ, CIDR des 8 subnets, identifiants DB |
| `network.tf` | VPC, 8 subnets (public/web/app/data ×2 AZ), IGW, **2 NAT**, routes |
| `security.tf` | chaîne de Security Groups (moindre privilège) |
| `data.tf` | RDS PostgreSQL **Multi-AZ** + DB subnet group |
| `app_tier.tf` | AMI, **ALB interne**, TG app, 2 EC2 app, attachements |
| `web_tier.tf` | **ALB public**, TG web, 2 EC2 web, attachements |
| `outputs.tf` | `site_url`, `rds_endpoint`, `internal_alb_dns` |
| `app/app.py` | API REST `/api/signup` (validation, hachage, INSERT paramétré) |
| `web/web.py` | formulaire + relais vers l'API interne |
| `*/user_data.sh.tpl` | bootstrap des EC2 (installe Flask/Gunicorn + lance le service) |
| `schema.sql` | table `users` (le schéma est aussi créé automatiquement par l'API au boot) |

## Chaîne de Security Groups (moindre privilège)

```
SG-alb-public   : 80 depuis 0.0.0.0/0
SG-web          : 80 depuis SG-alb-public
SG-alb-internal : 80 depuis SG-web
SG-app          : 80 depuis SG-alb-internal
SG-rds          : 5432 depuis SG-app
```

## Déploiement

```bash
cp .env.example .env        # mettre un vrai mot de passe dans TF_VAR_db_password
make tr_i                   # terraform init
make tr_a                   # apply (⚠ RDS Multi-AZ : ~10 min)
make url                    # affiche l'URL publique -> ouvrir dans le navigateur
```

Le **schéma SQL** est créé automatiquement par l'API au premier démarrage
(`CREATE TABLE IF NOT EXISTS`). Le fichier `schema.sql` reste fourni pour une création
manuelle si besoin (`psql -h <rds_endpoint> -U appuser -d signupdb -f schema.sql`).

### Test de bout en bout
1. Ouvrir `make url` dans le navigateur → le formulaire s'affiche.
2. Remplir et soumettre → message de succès.
3. Vérifier : `psql -h <rds_endpoint> -U appuser -d signupdb -c "SELECT id,email FROM users;"`
4. Un email en double → erreur 409 sans planter l'appli.

## ⚠️ Coûts & quotas (compte de formation partagé)

- **RDS, NAT Gateways et ALB sont facturés à l'heure** → `make tr_d` **obligatoire** en fin
  de séance, puis vérifier dans la console qu'il ne reste **ni RDS, ni NAT, ni EIP**.
- Cette archi consomme **4 EC2 (8 vCPU) + 2 NAT + 2 EIP + RDS Multi-AZ**. Sur un compte
  partagé saturé, l'`apply` peut buter sur les quotas (**vCPU**, **EIP**, **Elastic IP**). Si
  c'est le cas : déployer sur **une seule AZ** (mettre `azs = ["eu-west-3a"]` — réduit à
  2 EC2 + 1 NAT, mais RDS Multi-AZ exige 2 AZ dans le subnet group) ou attendre que des
  ressources se libèrent.

## Nettoyage (obligatoire)

```bash
make tr_d
```

## Réponses aux questions 1 à 5 → [`reponses.md`](reponses.md)
