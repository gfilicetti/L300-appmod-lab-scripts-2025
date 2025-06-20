#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CLUSTER=cepf-workstation-cluster
CONFIG=cepf-workstation-config 
WS=cepf-workstation 

# create a workstation
gcloud workstations create $WS \
    --region=$REGION \
    --config=$CONFIG \
    --cluster=$CLUSTER
