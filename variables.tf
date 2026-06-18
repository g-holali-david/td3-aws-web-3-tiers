variable "aws_region" {
  default = "eu-west-3"
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-3a", "eu-west-3b"]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# CIDR des 4 paires de subnets (public, web, app, data) repartis sur 2 AZ.
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "web_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.30.0/24", "10.0.31.0/24"]
}

# NB : pas de variable db_username / db_password / db_name : les identifiants de
# la base proviennent du secret AWS Secrets Manager "td-ipssi-rds-v2/password"
# (cf. data.tf -> local.rds_creds).
