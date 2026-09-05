# python-library-template
Template for a Python library that supports data science projects. Setup uses `pip`.

## Setup

##### Initialization

Install the project dependencies.
```
pip install -r requirements.txt
```

##### Common tasks

Run Jupyter Lab.
```
jupyter lab
```

Run tests.
```
pytest
```

## CLI

You can add a CLI endpoint by adding a console script to your packaging configuration:
```
[project.scripts]
data_toolkit = "my_data_toolkit.cli:app"
```
This allows you to run the following as an endpoint:
```
data_toolkit clean-csv input.csv output.csv
```


## Next Steps
- Drop datasets or exploratory files into `notebooks/`
- Turn notebook functions into reusable modules in `src/my_data_toolkit/`
- Add more tests in `tests/`


## Development

##### Setup

Use the following tools to ensure the code is cleaner, safer, and easier to maintain. Add them with:
```
pip install black isort mypy pytest
```

Use the following code to run all pre-commit files. Each pre-commit file is outlined below.
```
pre-commit run --all-files
```

##### `black`
Code Formatter. Enforces a consistent and clean code style. You don't need to argue about indentation or spacing ever again.
```
black src/ tests/
```

##### `isort`
Import Sorter. Automatically sorts imports alphabetically and groups them logically.
```
isort src/ tests/
```

##### `mypy`
Static type checker. Catches bugs before runtime by checking your type hints.
```
mypy src/
```

##### `pytest`
Testing framework. Clean, minimal testing tool with great plugin support.
```
pytest
```
