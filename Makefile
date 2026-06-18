ifeq ($(OS),Windows_NT)
SHELL := C:/PROGRA~1/Git/bin/bash.exe
.SHELLFLAGS := -c
endif

-include .env      
export

.DEFAULT_GOAL := help
.PHONY: help tr_i tr_l tr_p tr_a tr_d url clean

help: ## Affiche cette aide
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

tr_i: ## terraform init
	@terraform init -input=false

tr_l: ## Formate et valide la config
	@terraform fmt -check -recursive
	@terraform validate

tr_p: tr_l ## Previsualise le plan
	@terraform plan

tr_a: tr_p ## Deploie toute l'infra (RDS ~10 min)
	@terraform apply -auto-approve

tr_d: ## Detruit toute l'infra (OBLIGATOIRE : NAT + RDS factures)
	@terraform destroy -auto-approve

url: ## Affiche l'URL publique du site
	@terraform output -raw site_url

clean: tr_d ## Alias de tr_d
