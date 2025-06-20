#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
LOG_BUCKET_NAME="cepf_log_bucket"
LOG_SINK_NAME="cepf_log_routing_sink"

# 1. Create the Log Sink with Inclusion Filter
echo "Creating Log Sink: $LOG_SINK_NAME"
gcloud logging sinks create $LOG_SINK_NAME \
    --log-filter='resource.type="k8s_container"' \
    --destination="logging.googleapis.com/projects/$PROJECT_ID/locations/global/buckets/$LOG_BUCKET_NAME" \
    --project=$PROJECT_ID

echo "Log Sink '$LOG_SINK_NAME' created to route k8s_container logs to bucket '$LOG_BUCKET_NAME'."
