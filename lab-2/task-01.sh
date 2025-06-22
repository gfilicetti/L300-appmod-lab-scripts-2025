#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUM=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
REGION=us-central1
LOG_BUCKET_NAME="cepf_log_bucket"
BQ_DATASET_NAME="cepf_dataset"
SINK_NAME="${LOG_BUCKET_NAME}_to_${BQ_DATASET_NAME}_sink"

# 1. Create the Log Bucket
echo "Creating Log Bucket: $LOG_BUCKET_NAME"
gcloud logging buckets create "$LOG_BUCKET_NAME" \
    --location=global \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to create log bucket. Exiting."; exit 1; }

# 2. Create the BigQuery Dataset
echo "Creating BigQuery Dataset: $BQ_DATASET_NAME"
bq --location="$REGION" mk --dataset "$PROJECT_ID:$BQ_DATASET_NAME" || { echo "ERROR: Failed to create BigQuery dataset. Exiting."; exit 1; }

echo "Log Bucket '$LOG_BUCKET_NAME' and BigQuery Dataset '$BQ_DATASET_NAME' created."

echo "Script finished."