#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUM=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)") 
REGION=us-central1
LOG_BUCKET_NAME="cepf_log_bucket-$PROJECT_NUM"
BQ_DATASET_NAME="cepf_dataset"
EXTERNAL_TABLE_NAME="cepf_external_logs"

# 1. Create the Log Bucket
echo "Creating Log Bucket: $LOG_BUCKET_NAME"
gcloud logging buckets create --location=global $LOG_BUCKET_NAME --project=$PROJECT_ID

# 2. Create the BigQuery Dataset
echo "Creating BigQuery Dataset: $BQ_DATASET_NAME"
bq mk --location=$REGION --dataset $PROJECT_ID:$BQ_DATASET_NAME

echo "Log Bucket '$LOG_BUCKET_NAME' created and BigQuery Dataset '$BQ_DATASET_NAME' created."

# 3. Create an External Table linked to the Log Bucket
echo "Creating External Table: $EXTERNAL_TABLE_NAME"

STORAGE_URI="gs://$LOG_BUCKET_NAME"  

cat > logs_def.json <<EOF
{
  "source_uris": [
    "$STORAGE_URI/*.json"
  ],
  "source_format": "NEWLINE_DELIMITED_JSON"
}
EOF

# 4. Create an External Table linked to the definition
echo "Creating External Table: $EXTERNAL_TABLE_NAME"

# Use autodetect instead of providing a schema file or inline schema
bq mk --external_table_definition=logs_def.json \
    --autodetect \
    $PROJECT_ID:$BQ_DATASET_NAME.$EXTERNAL_TABLE_NAME

echo "External Table '$EXTERNAL_TABLE_NAME' created, linked to '$STORAGE_URI'."