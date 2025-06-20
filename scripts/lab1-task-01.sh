#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1

# create a configuration for cloud workstations instance
gcloud workstations configs create cepf-workstation-config \
    --region=$REGION \
    --idle-timeout=30m \
    --running-timeout=12h \
    --machine-type=e2-standard-4 \
    --container-registry-access-token-type=none \
    --enable-nested-virtualization

