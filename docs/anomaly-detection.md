<!-- SPDX-License-Identifier: MIT -->

# Anomaly Detection Integration

This document describes the integration of anomalib for anomaly detection in system metrics within the SystemManager.

## Overview

The SystemManager now includes anomaly detection capabilities using the anomalib library. Anomalies in system-wide CPU usage and memory consumption can be detected and logged.

## Setup

### 1. Install Anomalib

Anomalib requires Python. Create a virtual environment and install:

```bash
python3 -m venv anomalib_env
source anomalib_env/bin/activate
pip install anomalib
```

### 2. Collect Training Data

To train an anomaly detection model, collect normal system metrics data:

- Run the SystemManager CLI in daemon mode on a normal system.
- Sample metrics periodically and save to a CSV file with columns: cpu_usage, memory_usage.

Example script to collect data (run in Swift or Python):

```swift
// In a separate Swift script
import SystemObservation

let sampler = SystemMetricsSampler()
var data: [[Double]] = []

for _ in 0..<1000 {  // Collect 1000 samples
    if let metrics = sampler.sample() {
        data.append([metrics.cpuUsage, Double(metrics.memoryUsage)])
    }
    Thread.sleep(forTimeInterval: 1.0)  // 1 second interval
}

// Save to CSV (implement CSV writing)
```

### 3. Train the Model

Activate the virtual environment and train:

```bash
source anomalib_env/bin/activate
anomalib train --model padim --data_path normal_metrics.csv --output_path ./anomaly_model
```

Replace `padim` with a suitable model for time series (e.g., `dfm` or custom).

For synthetic data generation, run:

```bash
python scripts/train_dummy_model.py
```

This creates `synthetic_normal_data.csv` with dummy metrics. For training, convert data to images or use a time series model, then run anomalib CLI.

### 4. Configure SystemManager

Pass the model path when initializing SystemMetricsSampler:

```swift
let sampler = SystemMetricsSampler(modelPath: "/path/to/anomaly_model")
```

In CLI/UI, the model path can be provided via environment variable or config.

## Usage

- Run SystemManager in daemon mode: `sysman daemon`
- Anomalies with score > 0.5 are logged to console.
- Extend Supervisor to handle anomalies (e.g., alerts, actions).

## Notes

- Anomalib is primarily for image anomaly detection; adaptation for time series may require model selection.
- Ensure Python environment is activated when running Swift code that uses anomalib.
- Model training should be done on representative normal data to avoid false positives.