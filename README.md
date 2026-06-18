# TD3 — Application web 3-tiers sur AWS (Terraform)

Mastère Cybersécurité 5ᵉ année · IPSSI — AWS Academy.

Architecture **3-tiers** (présentation / application / données) en **Infrastructure as Code**.
Inscription d'un utilisateur : formulaire → API → **RDS PostgreSQL partagé**, via **deux Load
Balancers** (un public, un interne).

```
Internet → ALB public → tier WEB (Flask form) → ALB interne → tier APP (API) → RDS PostgreSQL
                         (subnets privés)                       (subnets privés)   (PARTAGE)
```

> **Tier données = RDS PARTAGÉ.** On ne crée PAS de base : on **réutilise** le RDS commun
> `td-ipssi-rds-v2` déjà déployé, et on récupère ses identifiants depuis **AWS Secrets
> Manager** (`td-ipssi-rds-v2/password`). C'est la consigne du prof.

## Structure

| Fichier | Rôle |
|---------|------|
| `providers.tf` | provider AWS `~> 5.0` |
| `variables.tf` | région, AZ, CIDR des 6 subnets (aucun secret en clair) |
| `network.tf` | VPC par défaut + IGW existante (data sources), 6 subnets (public/web/app ×2 AZ), **2 NAT**, routes |
| `security.tf` | chaîne de SG (alb-public → web → alb-internal → app) |
| `data.tf` | **data sources** : RDS partagé + secret Secrets Manager |
| `app_tier.tf` | AMI, **ALB interne**, TG app, 2 EC2 app (creds lus du secret) |
| `web_tier.tf` | **ALB public**, TG web, 2 EC2 web |
| `outputs.tf` | `site_url`, `rds_endpoint`, `internal_alb_dns` |
| `app/app.py`, `web/web.py` | API `/api/signup` + formulaire |
| `*/user_data.sh.tpl` | bootstrap EC2 (Flask/Gunicorn en service systemd) |

## Déploiement

```bash
cd td3-aws-web-3-tiers
make tr_i                 # terraform init
make tr_a                 # apply (pas de mot de passe a fournir : lu depuis Secrets Manager)
make url                  # -> ouvre l'URL dans le navigateur
make tr_d                 # OBLIGATOIRE en fin de seance (NAT + ALB factures)
```

> Aucun `TF_VAR_db_password` à définir : Terraform lit le secret `td-ipssi-rds-v2/password`.

## Accès direct à la base (ce que le prof veut voir)

```bash
# 1. Infos du RDS
aws rds describe-db-instances --db-instance-identifier td-ipssi-rds-v2 \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port,Engine:Engine,EngineVersion:EngineVersion}' --output table

# 2. Identifiants depuis Secrets Manager
CREDS=$(aws secretsmanager get-secret-value --secret-id td-ipssi-rds-v2/password --query SecretString --output text | jq .)
echo $CREDS

# 3. Connexion (mot de passe = champ "password" du secret)
psql -h td-ipssi-rds-v2.clqqieekmedc.eu-west-3.rds.amazonaws.com -U adminipssidb -d mydb -p 5432
```

## Sécurité (moindre privilège, ce qu'on gère)

```
SG-alb-public   : 80 depuis 0.0.0.0/0
SG-web          : 80 depuis SG-alb-public
SG-alb-internal : 80 depuis SG-web
SG-app          : 80 depuis SG-alb-internal
```
Le SG du RDS partagé (port 5432) est géré côté `td-ipssi-rds-v2` (hors de notre stack).

## Coûts & quotas (compte partagé)

- **NAT Gateways et ALB facturés à l'heure** → `make tr_d` **obligatoire** en fin de séance.
- Cette archi consomme **4 EC2 (8 vCPU) + 2 NAT + 2 EIP + 2 ALB** (le RDS, lui, est partagé →
  pas de coût RDS de notre côté). Si l'`apply` bute sur les quotas vCPU/EIP du compte
  partagé : passe `azs = ["eu-west-3a"]` (réduit à 2 EC2 + 1 NAT).

## Réponses aux questions 1 à 5 → [`reponses.md`](reponses.md)
