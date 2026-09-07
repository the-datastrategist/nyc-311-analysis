# Makefile without run_dbt.py

.DEFAULT_GOAL := help

# Load .env variables
ifneq ("$(wildcard .env)","")
	include .env
	export $(shell sed 's/=.*//' .env)
endif

DBT_PROFILES_DIR ?= $(CURDIR)/profiles
export DBT_PROFILES_DIR

IMAGE_NAME ?= $(notdir $(CURDIR))

# Load .env and Google credentials into the Docker container
DOCKER_RUN = docker run --rm \
	--env-file .env \
	-v "$(GOOGLE_APPLICATION_CREDENTIALS):/app/credentials.json:ro" \
	-e GOOGLE_APPLICATION_CREDENTIALS=/app/credentials.json \
	$(IMAGE_NAME)

.PHONY: dbt docker-run build dbt-build debug docs serve-docs test seed help
dbt: ## Run dbt with ARGS, e.g. `make dbt ARGS="run --select stg_users"`
	dbt $(ARGS)

dbt-run: ## Run dbt with ARGS, e.g. `make dbt ARGS="run --select stg_users"`
	dbt run $(ARGS)

docker-run: ## Run a command in the Docker image, e.g. `make docker-run ARGS="dbt debug"`
	$(DOCKER_RUN) $(ARGS)

build: ## Build the Docker image
	docker build -t $(IMAGE_NAME) .

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
