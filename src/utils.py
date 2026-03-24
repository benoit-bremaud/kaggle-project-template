"""Shared utility functions for data processing and model evaluation."""

from pathlib import Path

import pandas as pd


def load_data(data_dir: Path) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Load train and test datasets from the raw data directory.

    Args:
        data_dir: Path to the raw data directory containing train.csv and test.csv.

    Returns:
        Tuple of (train_df, test_df).
    """
    train_df = pd.read_csv(data_dir / "train.csv")
    test_df = pd.read_csv(data_dir / "test.csv")
    return train_df, test_df


def save_submission(
    predictions: pd.Series,
    ids: pd.Series,
    target_col: str,
    output_path: Path,
    id_col: str = "Id",
) -> pd.DataFrame:
    """Create and save a Kaggle submission CSV.

    Args:
        predictions: Model predictions for the test set.
        ids: ID column values from the test set.
        target_col: Name of the target column in submission.
        output_path: Path to save the submission CSV.
        id_col: Name of the ID column (default: "Id").

    Returns:
        The submission DataFrame.
    """
    submission = pd.DataFrame({id_col: ids, target_col: predictions})
    submission.to_csv(output_path, index=False)
    return submission
