#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUM=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)") 
LOG_BUCKET_NAME="cepf_log_bucket-$PROJECT_NUM"
LOG_SINK_NAME="cepf_log_routing_sink"