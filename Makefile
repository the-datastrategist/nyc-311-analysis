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

# BigQuery connection used by AI.GENERATE() (see vars.bq_ai_connection_id in dbt_project.yml)
BQ_AI_CONNECTION_LOCATION ?= us
BQ_AI_CONNECTION_NAME ?= vertex_gemini

# Load .env and Google credentials into the Docker container
DOCKER_RUN = docker run --rm \
	--env-file .env \
	-v "$(GOOGLE_APPLICATION_CREDENTIALS):/app/credentials.json:ro" \
	-e GOOGLE_APPLICATION_CREDENTIALS=/app/credentials.json \
	$(IMAGE_NAME)

.PHONY: dbt docker-run build dbt-build debug docs serve-docs test seed train predict train-with-vars init-ai-connection help
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

train: ## Train a BQML model config, e.g. `make train CONFIG=next_day_requests_xgboost`
	@if [ -z "$(CONFIG)" ]; then echo "Usage: make train CONFIG=<model_name>"; exit 1; fi
	$(DOCKER_RUN) dbt run-operation train_bqml_model --args '{model_name: $(CONFIG)}'

predict: ## Predict with a BQML model config, e.g. `make predict CONFIG=next_day_requests_xgboost`
	@if [ -z "$(CONFIG)" ]; then echo "Usage: make predict CONFIG=<model_name>"; exit 1; fi
	$(DOCKER_RUN) dbt run-operation predict_bqml_model --args '{model_name: $(CONFIG)}'

VARS ?= {}
train-with-vars: ## Predict with a BQML model config using --vars, e.g. `make train-with-vars CONFIG=next_day_requests_xgboost VARS='{predict_min_year: 2022}'`
	@if [ -z "$(CONFIG)" ]; then echo "Usage: make train-with-vars CONFIG=<model_name> VARS='{key: value}'"; exit 1; fi
	$(DOCKER_RUN) dbt run-operation predict_bqml_model --args '{model_name: $(CONFIG)}' --vars '$(VARS)'

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

init-ai-connection: ## One-time setup: create the BQ connection + IAM bindings needed for AI.GENERATE() (idempotent)
	@if [ -z "$(GOOGLE_PROJECT_ID)" ]; then echo "GOOGLE_PROJECT_ID not set (check .env)"; exit 1; fi
	@if [ -z "$(GOOGLE_APPLICATION_CREDENTIALS)" ]; then echo "GOOGLE_APPLICATION_CREDENTIALS not set (check .env)"; exit 1; fi
	@echo "Ensuring BigQuery connection $(BQ_AI_CONNECTION_LOCATION).$(BQ_AI_CONNECTION_NAME) exists..."
	@bq show --connection "$(GOOGLE_PROJECT_ID).$(BQ_AI_CONNECTION_LOCATION).$(BQ_AI_CONNECTION_NAME)" >/dev/null 2>&1 || \
		bq mk --connection --project_id="$(GOOGLE_PROJECT_ID)" --connection_type=CLOUD_RESOURCE \
			--location=$(BQ_AI_CONNECTION_LOCATION) $(BQ_AI_CONNECTION_NAME)
	$(eval CONNECTION_SA := $(shell bq show --format=json --connection "$(GOOGLE_PROJECT_ID).$(BQ_AI_CONNECTION_LOCATION).$(BQ_AI_CONNECTION_NAME)" | python3 -c "import json,sys; print(json.load(sys.stdin)['cloudResource']['serviceAccountId'])"))
	$(eval DBT_SA := $(shell python3 -c "import json; print(json.load(open('$(GOOGLE_APPLICATION_CREDENTIALS)'))['client_email'])"))
	@echo "Granting roles/aiplatform.user to connection service account $(CONNECTION_SA)..."
	@gcloud projects add-iam-policy-binding "$(GOOGLE_PROJECT_ID)" \
		--member="serviceAccount:$(CONNECTION_SA)" \
		--role="roles/aiplatform.user" \
		--condition=None >/dev/null
	@echo "Granting roles/bigquery.connectionUser on the connection to $(DBT_SA)..."
	@bq add-iam-policy-binding --connection \
		--member="serviceAccount:$(DBT_SA)" \
		--role="roles/bigquery.connectionUser" \
		"$(GOOGLE_PROJECT_ID).$(BQ_AI_CONNECTION_LOCATION).$(BQ_AI_CONNECTION_NAME)" >/dev/null
	@echo "AI.GENERATE() connection $(BQ_AI_CONNECTION_LOCATION).$(BQ_AI_CONNECTION_NAME) is ready."

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "🔹 %-20s %s\n", $$1, $$2}'
