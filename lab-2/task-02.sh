#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
LOG_BUCKET_NAME="cepf_log_bucket"
LOG_SINK_NAME="cepf_log_routing_sink"
BQ_DATASET_NAME="cepf_dataset"
SINK_DESTINATION="bigquery.googleapis.com/projects/$PROJECT_ID/datasets/$BQ_DATASET_NAME"

# 1. Create a log sink to route logs from the bucket to the BigQuery dataset
echo "Creating log sink '$LOG_SINK_NAME' to route logs to our log bucket..."

gcloud logging sinks create "$LOG_SINK_NAME" "$SINK_DESTINATION" \
  --log-filter='resource.type="k8s_container"' \
  --project="$PROJECT_ID" || { echo "ERROR: Failed to create log sink. Exiting."; exit 1; }

echo "Log Sink '$LOG_SINK_NAME' created to route k8s_container logs to bucket '$LOG_BUCKET_NAME'."

# 2. Grant permissions to the sink's service account
echo "Granting BigQuery Data Editor role to the sink's service account..."
WRITER_IDENTITY=$(gcloud logging sinks describe "$LOG_SINK_NAME" --project="$PROJECT_ID" --format='value(writerIdentity)')

if [ -z "$WRITER_IDENTITY" ]; then
    echo "ERROR: Could not retrieve writer identity for sink '$LOG_SINK_NAME'. Exiting."
    exit 1
fi

bq add-iam-policy-binding --member="$WRITER_IDENTITY" --role='roles/bigquery.dataEditor' "$PROJECT_ID:$BQ_DATASET_NAME" > /dev/null

echo "Permissions granted. The log bucket '$LOG_BUCKET_NAME' is now receiving logs via the sink '$LOG_SINK_NAME'."

echo "Script finished."
