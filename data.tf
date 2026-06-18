# --- Tier DONNEES : on UTILISE le RDS PARTAGE existant (td-ipssi-rds-v2).
# On ne le cree PAS : on le LIT via data sources, et on recupere les
# identifiants depuis AWS Secrets Manager (jamais de mot de passe en clair). ---

data "aws_db_instance" "shared" {
  db_instance_identifier = "td-ipssi-rds-v2"
}

data "aws_secretsmanager_secret" "rds" {
  name = "td-ipssi-rds-v2/password"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

locals {
  # Le secret est un JSON : { "db_name": ..., "username": ..., "password": ... }
  rds_creds = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)
}
