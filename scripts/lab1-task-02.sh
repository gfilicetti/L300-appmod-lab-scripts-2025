#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1

# create a workstation
gcloud workstations create cepf-workstation \
    --region=$REGION \
    --config=cepf-workstation-config \
    --cluster=cepf-workstation-cluster
