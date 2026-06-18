variable "aws_region" {
  default = "eu-west-3"
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-3a", "eu-west-3b"]
}

# Prefixe des noms (unique par etudiant : evite les collisions de noms
# SG / ALB / TG dans le VPC par defaut PARTAGE).
variable "name_prefix" {
  default = "td3-dany-david"
}

# CIDR des subnets, dans le VPC par defaut (172.31.0.0/16).
# Plages choisies libres au moment du TD (verifier qu'aucun camarade ne les prend).
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.110.0/24", "172.31.111.0/24"]
}

variable "web_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.112.0/24", "172.31.113.0/24"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.114.0/24", "172.31.115.0/24"]
}

# NB : pas de subnets "data" ni de variable db_* : le tier donnees est le RDS
# PARTAGE (td-ipssi-rds-v2), lu via data source, identifiants depuis Secrets
# Manager (cf. data.tf -> local.rds_creds).
