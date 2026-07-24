import pandas as pd
from pandas.testing import assert_frame_equal


def compare_dataframes(
    gold_df: pd.DataFrame,
    generated_df: pd.DataFrame,
    order_sensitive: bool = False,
) -> bool:

    gold_df = gold_df.copy()
    generated_df = generated_df.copy()

    # Same number of rows.
    if len(gold_df) != len(generated_df):
        return False

    # Normalize column names.
    gold_df.columns = [
        str(column).strip().lower()
        for column in gold_df.columns
    ]

    generated_df.columns = [
        str(column).strip().lower()
        for column in generated_df.columns
    ]

    # All required gold columns must exist.
    if not set(gold_df.columns).issubset(
        set(generated_df.columns)
    ):
        return False

    # Ignore extra generated columns.
    generated_df = generated_df[
        list(gold_df.columns)
    ]

    # Handle row order.
    if order_sensitive:
        gold_df = gold_df.reset_index(drop=True)
        generated_df = generated_df.reset_index(drop=True)

    else:
        columns = list(gold_df.columns)

        gold_df = (
            gold_df
            .sort_values(by=columns, na_position="first")
            .reset_index(drop=True)
        )

        generated_df = (
            generated_df
            .sort_values(by=columns, na_position="first")
            .reset_index(drop=True)
        )

    try:
        assert_frame_equal(
            gold_df,
            generated_df,
            check_dtype=False,
        )
        return True

    except AssertionError:
        return False