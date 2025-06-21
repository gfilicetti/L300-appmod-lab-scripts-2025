#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
LOG_BUCKET_NAME="cepf_log_bucket"
BQ_DATASET_NAME="cepf_dataset"

# 1. Create the Log Bucket
echo "Creating Log Bucket: $LOG_BUCKET_NAME"
gcloud logging buckets create --location=global $LOG_BUCKET_NAME --project=$PROJECT_ID

# 2. Create the BigQuery Dataset linked to the Log Bucket
echo "Creating BigQuery Dataset: $BQ_DATASET_NAME"
bq mk --location=$REGION --dataset $PROJECT_ID:$BQ_DATASET_NAME

echo "Log Bucket '$LOG_BUCKET_NAME' created and BigQuery Dataset '$BQ_DATASET_NAME' created."
