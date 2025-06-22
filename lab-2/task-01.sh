#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUM=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
REGION=us-east4
LOG_BUCKET_NAME="cepf_log_bucket"
BQ_DATASET_NAME="cepf_dataset"
SINK_NAME="${LOG_BUCKET_NAME}_to_${BQ_DATASET_NAME}_sink"

# 1. Create the Log Bucket
# make sure to enable analytics so we can connect it to BQ
echo "Creating Log Bucket: $LOG_BUCKET_NAME"
gcloud logging buckets create "$LOG_BUCKET_NAME" \
    --location=global \
    --enable-analytics \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to create log bucket. Exiting."; exit 1; }

# 2. Create a BigQuery Dataset linked to this bucket
echo "Creating the linked BigQuery Dataset: $BQ_DATASET_NAME"
gcloud logging links create $BQ_DATASET_NAME \
  --location=global \
  --project=$PROJECT_ID \
  --bucket=$LOG_BUCKET_NAME || { echo "ERROR: Failed to create the linked BigQuery dataset. Exiting."; exit 1; }

echo "Log Bucket '$LOG_BUCKET_NAME' and BigQuery Dataset '$BQ_DATASET_NAME' created and linked."

echo "Script finished."