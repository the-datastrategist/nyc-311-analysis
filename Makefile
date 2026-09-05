# Makefile without run_dbt.py

.DEFAULT_GOAL := help

# Load .env variables
ifneq ("$(wildcard .env)","")
	include .env
	export $(shell sed 's/=.*//' .env)
endif

.PHONY: dbt build dbt-build debug docs serve-docs test seed help
dbt: ## Run dbt with ARGS, e.g. `make dbt ARGS="run --select stg_users"`
	dbt $(ARGS)

dbt-run: ## Run dbt with ARGS, e.g. `make dbt ARGS="run --select stg_users"`
	dbt run $(ARGS)

build: ## Build the Docker image
	docker build -t nyc-311-analysis .

dbt-build: ## Run dbt build locally
	$(MAKE) dbt ARGS="build"

debug: ## Run dbt debug
	$(MAKE) dbt ARGS="debug"

docs: ## Generate dbt docs
	$(MAKE) dbt ARGS="docs generate"

serve-docs: ## Serve dbt docs locally
	$(MAKE) dbt ARGS="docs serve"

test: ## Run dbt tests
	$(MAKE) dbt ARGS="test"

seed: ## Run dbt seed
	$(MAKE) dbt ARGS="seed"

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "🔹 %-20s %s\n", $$1, $$2}'
