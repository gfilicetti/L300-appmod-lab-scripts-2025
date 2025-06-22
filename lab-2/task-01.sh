#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUM=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
REGION=us-central1
LOG_BUCKET_NAME="cepf_log_bucket-$PROJECT_NUM"
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

# 3. Create a log sink to route logs from the bucket to the BigQuery dataset
echo "Creating log sink '$SINK_NAME' to link bucket to BigQuery dataset..."
SINK_DESTINATION="bigquery.googleapis.com/projects/$PROJECT_ID/datasets/$BQ_DATASET_NAME"

gcloud logging sinks create "$SINK_NAME" "$SINK_DESTINATION" \
  --log-bucket="$LOG_BUCKET_NAME" \
  --project="$PROJECT_ID" || { echo "ERROR: Failed to create log sink. Exiting."; exit 1; }

# 4. Grant permissions to the sink's service account
echo "Granting BigQuery Data Editor role to the sink's service account..."
WRITER_IDENTITY=$(gcloud logging sinks describe "$SINK_NAME" --project="$PROJECT_ID" --format='value(writerIdentity)')

if [ -z "$WRITER_IDENTITY" ]; then
    echo "ERROR: Could not retrieve writer identity for sink '$SINK_NAME'. Exiting."
    exit 1
fi

bq add-iam-policy-binding --member="$WRITER_IDENTITY" --role='roles/bigquery.dataEditor' "$PROJECT_ID:$BQ_DATASET_NAME" > /dev/null

echo "Permissions granted. The log bucket '$LOG_BUCKET_NAME' is now linked to BigQuery dataset '$BQ_DATASET_NAME' via the sink '$SINK_NAME'."
echo "Script finished."