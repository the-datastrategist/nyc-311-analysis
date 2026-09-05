# python-library-template
Template for a Python library that supports data science projects. Setup uses `poetry`.

## Setup

##### Initialization

Initialize poetry.
```
poetry install
```

Install poetry dependencies.
```
bash scripts/install_dependencies.sh
```


##### Common tasks

Run Jupyter Lab.
```
poetry run jupyter lab
```

Run tests.
```
poetry run pytest
```

## CLI

You can add a CLI endpoint by adding the following code to `pyproject.toml`:
```
[tool.poetry.scripts]
data_toolkit = "my_data_toolkit.cli:app"
```
This allows you to run the following as an endpoint:
```
poetry run data_toolkit clean-csv input.csv output.csv
```


## Next Steps
- Drop datasets or exploratory files into `notebooks/`
- Turn notebook functions into reusable modules in `src/my_data_toolkit/`
- Add more tests in `tests/`
- Use `poetry build` and `poetry publish` when you're ready to share


## Development

##### Setup

Use the following tools to ensure the code is cleaner, safer, and easier to maintain. Add the following tools using the command:
```
poetry add --group dev black isort mypy pytest
```

Use the following code to run all pre-commit files. Each pre-commit file is outlined below.
```
poetry run pre-commit run --all-files
```

##### `black`
Code Formatter. Enforces a consistent and clean code style. You don't need to argue about indentation or spacing ever again.
```
poetry run black src/ tests/
```

##### `isort`
Import Sorter. Automatically sorts imports alphabetically and groups them logically.
```
poetry run isort src/ tests/
```

##### `mypy`
Static type checker. Catches bugs before runtime by checking your type hints.
```
poetry run mypy src/
```

##### `pytest`
Testing framework. Clean, minimal testing tool with great plugin support.
```
poetry run pytest
```
