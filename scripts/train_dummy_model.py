#!/usr/bin/env python3
"""
Script to generate a dummy anomalib model for SystemManager anomaly detection.
This creates synthetic normal data and trains a simple model.
"""

import numpy as np
import pandas as pd


def generate_synthetic_data(num_samples=1000):
    """Generate synthetic normal system metrics data."""
    np.random.seed(42)

    # Create DataFrame with 'image' column for anomalib
    # (hack for time series; normally convert metrics to images)
    data = pd.DataFrame(
        {
            "image_path": [f"dummy_{i}.png" for i in range(num_samples)],
            "label": ["normal"] * num_samples,
        }
    )

    return data


if __name__ == "__main__":
    # Generate synthetic data
    print("Generating synthetic normal data...")
    data = generate_synthetic_data()
    data_path = "synthetic_normal_data.csv"
    data.to_csv(data_path, index=False)

    print(f"Synthetic data saved to {data_path}")
    print("To train a model, use anomalib CLI with image data.")
    print("Example: anomalib train --model padim --data folder")
    print("  --data_path /path/to/images --output ./model")
    print("Note: Anomalib is for images; adapt for time series.")
