from my_data_toolkit.preprocessing import clean_column_names
import pandas as pd

def test_clean_column_names():
    df = pd.DataFrame(columns=["First Name", " Last Name ", "AGE"])
    df_clean = clean_column_names(df)
    assert df_clean.columns.tolist() == ["first_name", "last_name", "age"]
