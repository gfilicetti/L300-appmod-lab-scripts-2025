#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
LOG_BUCKET_NAME="cepf_log_bucket"
LOG_SINK_NAME="cepf_log_routing_sink"

# 1. Create the Log Sink with Inclusion Filter
echo "Creating Log Sink: $LOG_SINK_NAME"
gcloud logging sinks create $LOG_SINK_NAME \
    storage.googleapis.com/$LOG_BUCKET_NAME \
    --log-filter='resource.type="k8s_container"' \
    --project=$PROJECT_ID

echo "Log Sink '$LOG_SINK_NAME' created to route k8s_container logs to bucket '$LOG_BUCKET_NAME'."

# 2. Grant permissions
echo "Granting Storage Object Creator to the Logging Service Account"
gcloud storage buckets add-iam-policy-binding gs://$LOG_BUCKET_NAME \
    --member=serviceAccount:service-14723777617@gcp-sa-logging.iam.gserviceaccount.com \
    --role=roles/storage.objectCreator

