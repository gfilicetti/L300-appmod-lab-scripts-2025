#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CLUSTER=cepf-workstation-cluster
CONFIG=cepf-workstation-config 

# create a configuration for cloud workstations instance
gcloud workstations configs create $CONFIG \
    --cluster=$CLUSTER \
    --region=$REGION \
    --machine-type=e2-standard-4
    # --enable-nested-virtualization

