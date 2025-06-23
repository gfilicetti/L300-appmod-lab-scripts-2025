#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="cepf-gke-cluster"
FLEET_HOST_PROJECT=$(gcloud config get-value project) 
# Qwiklabs will give you a zone to use in the instructions once the environment is provisioned. Use that zone here.
ZONE="us-west1-c" # use Zone given to you by qwiklabs

# 1. Create the Enterprise mode GKE cluster
echo "Creating Enterprise GKE cluster: $CLUSTER_NAME"
gcloud beta container clusters create $CLUSTER_NAME \
    --zone $ZONE \
    --tier "enterprise" \
    --no-enable-basic-auth \
    --cluster-version "1.32.4-gke.1415000" \
    --release-channel "regular" \
    --machine-type "e2-medium" \
    --image-type "COS_CONTAINERD" \
    --disk-type "pd-balanced" \
    --disk-size "100" \
    --metadata disable-legacy-endpoints=true \
    --num-nodes "3" \
    --enable-ip-alias \
    --no-enable-intra-node-visibility \
    --default-max-pods-per-node "110" \
    --enable-ip-access \
    --security-posture=standard \
    --workload-vulnerability-scanning=enterprise \
    --no-enable-google-cloud-access \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
    --enable-autoupgrade \
    --enable-autorepair \
    --max-surge-upgrade 1 \
    --max-unavailable-upgrade 0 \
    --binauthz-evaluation-mode=DISABLED \
    --enable-managed-prometheus \
    --workload-pool "$PROJECT_ID.svc.id.goog" \
    --enable-shielded-nodes \
    --shielded-integrity-monitoring \
    --no-shielded-secure-boot \
    --fleet-project=$PROJECT_ID \
    --project $PROJECT_ID 

echo "GKE Cluster '$CLUSTER_NAME' created and registered to the fleet."

echo ""
echo "Next steps:"
echo "1.  The script assumes an Anthos cluster on bare metal ('cepf-bare-metal-cluster') already exists."
echo "2.  To log in to the Anthos cluster, use the Google Cloud Console. Navigate to"
echo "    Kubernetes Clusters, select 'cepf-bare-metal-cluster', and use the 'Connect'"
echo "    button to log in with your Google identity."
echo ""
