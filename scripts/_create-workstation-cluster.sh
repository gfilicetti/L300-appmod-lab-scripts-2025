#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
CLUSTER=cepf-workstation-cluster
REGION=us-central1
NETWORK=default
SUBNETWORK=default

# create a workstation cluster
gcloud workstations clusters create $CLUSTER \
    --region=$REGION \
    --network=projects/$PROJECT_ID/global/networks/$NETWORK \
    --subnetwork=projects/$PROJECT_ID/regions/$REGION/subnetworks/$SUBNETWORK
