#!/bin/bash

# dbt
poetry add dbt-core
poetry add dbt-bigquery
# or dbt-postgres, dbt-bigquery, dbt-snowflake, etc.

# Environment variables
poetry add python-dotenv

# Add development dependencies
poetry add --group dev black isort mypy pytest

# Add pre-commit
poetry add --group dev pre-commit

# Add typer (for CLIs)
poetry add typer[all]

# Install git hooks
# Runs all libraries above before every commit
poetry run pre-commit install

# Specify DBT_PROFILES_DIR
# export DBT_PROFILES_DIR=$(pwd)/profiles
