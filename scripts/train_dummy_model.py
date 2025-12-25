# SPDX-License-Identifier: MIT

#!/usr/bin/env python3
"""
Script to generate a dummy anomalib model for SystemManager anomaly detection.
This creates synthetic normal data and trains a simple model.
"""

import logging
import numpy as np
import pandas as pd

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


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
    logger.info("Generating synthetic normal data...")
    data = generate_synthetic_data()
    data_path = "synthetic_normal_data.csv"
    data.to_csv(data_path, index=False)

    logger.info(f"Synthetic data saved to {data_path}")
    logger.info("To train a model, use anomalib CLI with image data.")
    logger.info("Example: anomalib train --model padim --data folder")
    logger.info("  --data_path /path/to/images --output ./model")
    logger.warning("Note: Anomalib is for images; adapt for time series.")
