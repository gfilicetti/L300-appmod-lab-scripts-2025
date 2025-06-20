#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1

# **NOTE** This operation takes 30 minutes to complete. But in the Lab Env it will already be there

# create a configuration for cloud workstations instance
gcloud workstations configs create cepf-workstation-config \
    --region=$REGION \
    --container-image=us-docker.pkg.dev/cloud-workstations/samples/code-oss:latest
