#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="cepf-gke-cluster"
FLEET_HOST_PROJECT=$(gcloud config get-value project) 
ZONE="us-central1-a"

# 1. Create the Standard mode GKE cluster
echo "Creating Standard GKE cluster: $CLUSTER_NAME"
gcloud container clusters create $CLUSTER_NAME \
    --zone=$ZONE \
    --cluster-version=latest \
    --release-channel=regular \
    --machine-type=e2-standard-4 \
    --num-nodes=3 \
    --workload-pool=$PROJECT_ID.svc.id.goog \
    --project=$PROJECT_ID

# 2. Register the GKE cluster to the fleet
echo "Registering GKE cluster to fleet: $CLUSTER_NAME"
gcloud container fleet memberships register $CLUSTER_NAME-membership \
    --gke-uri=https://container.googleapis.com/v1/projects/$PROJECT_ID/zones/$ZONE/clusters/$CLUSTER_NAME \
    --project=$PROJECT_ID

echo "GKE Cluster '$CLUSTER_NAME' created and registered to the fleet."

echo ""
echo "Next steps:"
echo "1.  The script assumes an Anthos cluster on bare metal ('cepf-bare-metal-cluster') already exists."
echo "2.  To log in to the Anthos cluster, use the Google Cloud Console. Navigate to"
echo "    Kubernetes Clusters, select 'cepf-bare-metal-cluster', and use the 'Connect'"
echo "    button to log in with your Google identity."
echo ""
