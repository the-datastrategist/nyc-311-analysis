# NYC 311 Request Forecast

A simple production ML platform that forecasts NYC 311 Requests and generates
AI-produced insights.

## Setup

##### Initialization

Initialize the project. The make commands below run on a Docker image.
```
make build
```

Initialize dbt.
```
make dbt-build
```


##### Running dbt models

Run all dbt models.
```
make dbt-run
```

Run a specific model.
```
make dbt-run ARGS='--select my_model_config'
```

## ML Ops

##### Configuration

This project forecasting platform runs in BigQueryML.
We add variables to `dbt_profile.yml` to track specify feature sets
and model configuations.

- `vars.feature_sets` allows you to group several features into an
individual set, which can be referenced in `vars.model_configs[i].feature_set_groups`.
- `vars.model_configs[i]` contains 

__Sample model configuration.__

See the [BigQueryML docs](https://docs.cloud.google.com/bigquery/docs/bqml-introduction) for
more details on BQML specifications.

```
- model_name: agency_next_day_requests_xgboost  # Model name; must be unique
    version: v1.0                               # Model version    
    lifecycle: prod                             # Model lifecycle: prod, dev, experiment
    interval: day                               # Date interval (default = day) 
    include_in_run: true
    model_type: BOOSTED_TREE_REGRESSOR
    input_label_cols:                   # Outcome variable; must be a single string in list
        - requests_next_1day
    parameters:                         # Model parameters
        booster_type: GBTREE
        num_parallel_tree: 1
        max_iterations: 50
        learn_rate: 0.1
        max_tree_depth: 6
        min_tree_child_weight: 1
        min_split_loss: 0.0
        subsample: 0.8
        colsample_bytree: 0.8
        colsample_bylevel: 0.8
        colsample_bynode: 0.8
        l1_reg: 0.1
        l2_reg: 0.1
        early_stop: true
        min_rel_progress: 0.001
        data_split_method: SEQ
        data_split_eval_fraction: 0.2
        data_split_col: asof_date
        enable_global_explain: true
    feature_set_groups:         # feature groups specified above
        - datetime
        - request_counts
        - request_metrics
        - requests_period_over_period
        feature_columns:
        - agency_code
        - asof_date
    data:
        train:
            source_sql: |
                select *
                from `the-data-strategist`.`nyc_311_analysis`.`int_agency_daily_features`
                where extract(year from asof_date) between 2019 and 2020
        predict:
            source_sql: |
                select *
                from `the-data-strategist`.`nyc_311_analysis`.`int_agency_daily_features`
                where extract(year from asof_date) >= {{ var('predict_min_year', 2021) }}
                output_table: ml_agency_daily_predictions
                outcome_field: predicted_requests_next_1day
            id_fields:
            - agency_code
            - asof_date

```

##### Running an ML model

Model configurations are managed in `dbt_project.yml` via `vars.model_configs`.

We break the ML workflow into these processes:
- `make train CONFIG=<model_name>`: Trains, evaluates, and stores a specified model.
- `make predict CONFIG=<model_name>`: Generates a prediction based on a saved model.


## Next Steps

1. Copy `.env.example` to `.env` and update the variables.
2. Review `dbt_project.yml` and make adjustments if needed.
3. Train a model with `make train CONFIG=agency_next_day_requests_xgboost`.
4. Generate a prediction with `make predict CONFIG=agency_next_day_requests_xgboost`.
5. View a business and ML observability report [here](https://datastudio.google.com/reporting/d8cc9e89-40a5-4590-9649-7b04429dfa3a).
