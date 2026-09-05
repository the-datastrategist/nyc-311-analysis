# Makefile without run_dbt.py

.DEFAULT_GOAL := help

# Load .env variables
ifneq ("$(wildcard .env)","")
	include .env
	export $(shell sed 's/=.*//' .env)
endif

.PHONY: dbt
dbt: ## Run dbt with ARGS, e.g. `make dbt ARGS="run --select stg_users"`
	poetry run dbt $(ARGS)

debug: ## Run dbt debug
	make dbt ARGS="debug"

build: ## Run dbt build
	make dbt ARGS="build"

docs: ## Generate dbt docs
	make dbt ARGS="docs generate"

serve-docs: ## Serve dbt docs locally
	make dbt ARGS="docs serve"

test: ## Run dbt tests
	make dbt ARGS="test"

seed: ## Run dbt seed
	make dbt ARGS="seed"

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "🔹 %-20s %s\n", $$1, $$2}'
