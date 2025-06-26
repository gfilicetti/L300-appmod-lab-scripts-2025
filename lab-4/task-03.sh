#!/bin/bash

# This script enables multi-cluster gateways and services for GKE clusters
# by registering them to a fleet and enabling fleet ingress.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
# These should be consistent with the values used in task-02.sh.
PROJECT_ID=$(gcloud config get-value project)
# NOTE: Qwiklabs will give you a region to use in the instructions once the environment is provisioned. Use that region here.
REGION1="us-west1" # Lab start region / location of the first cluster
ZONE1="$REGION1-a" # the zone for gke cluster 1
REGION2="europe-west4"    # Location of the second cluster
ZONE2="$REGION2-a" # the zone for gke cluster 2

# IMPORTANT: Update with the names of your GKE clusters, consistent with task-02.sh
CLUSTER1_NAME="cepf-gke-cluster-1"
CLUSTER2_NAME="cepf-gke-cluster-2"

# Fleet membership names as specified in the task
MEMBERSHIP1_NAME="${CLUSTER1_NAME}-membership"
MEMBERSHIP2_NAME="${CLUSTER2_NAME}-membership"

# The fleet host project is typically the same as the project ID
FLEET_HOST_PROJECT=$PROJECT_ID

# --- Script Execution ---

echo "--- Task 3: Enable Multi-Cluster Gateways ---"
echo ""

# 2. Pre-requisite: Enable Workload Identity on GKE clusters
# This is required for fleet registration and secure inter-service communication.
echo "Enabling Workload Identity on both clusters..."
gcloud container clusters update "${CLUSTER1_NAME}" --zone="${ZONE1}" --workload-pool="${PROJECT_ID}.svc.id.goog" --project="${PROJECT_ID}"
gcloud container clusters update "${CLUSTER2_NAME}" --zone="${ZONE2}" --workload-pool="${PROJECT_ID}.svc.id.goog" --project="${PROJECT_ID}"
echo "Workload Identity enabled."
echo ""
 
# 3. Pre-requisite: Install Gateway API CRDs on GKE clusters
# This is a crucial step as Fleet Ingress relies on the Gateway API.
echo "Installing Gateway API CRDs on both clusters..."
gcloud container clusters get-credentials "${CLUSTER1_NAME}" --zone "${ZONE1}" --project "${PROJECT_ID}"
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml"
 
gcloud container clusters get-credentials "${CLUSTER2_NAME}" --zone "${ZONE2}" --project "${PROJECT_ID}"
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml"
 
echo "Gateway API CRDs installed."
 
# 4. Register both clusters to the fleet
# Registering clusters to a fleet allows them to be managed centrally and enables fleet features.
echo "Registering GKE cluster '$CLUSTER1_NAME' to fleet with membership '$MEMBERSHIP1_NAME'..."
gcloud container fleet memberships register $MEMBERSHIP1_NAME \
    --gke-uri=https://container.googleapis.com/v1/projects/$PROJECT_ID/locations/$ZONE1/clusters/$CLUSTER1_NAME \
    --enable-workload-identity \
    --project=$PROJECT_ID || { echo "ERROR: Failed to register $CLUSTER1_NAME. Exiting."; exit 1; }

echo "Registering GKE cluster '$CLUSTER2_NAME' to fleet with membership '$MEMBERSHIP2_NAME'..."
gcloud container fleet memberships register $MEMBERSHIP2_NAME \
    --gke-uri=https://container.googleapis.com/v1/projects/$PROJECT_ID/locations/$ZONE2/clusters/$CLUSTER2_NAME \
    --enable-workload-identity \
    --project=$PROJECT_ID || { echo "ERROR: Failed to register $CLUSTER2_NAME. Exiting."; exit 1; }

echo "Clusters registered to the fleet."

# 5. Enable multi-cluster services (MCS)
# MCS allows services to be discovered and accessed across clusters in the fleet.
echo "Enabling multi-cluster services for the fleet..."
gcloud container fleet multi-cluster-services enable --project=$PROJECT_ID || { echo "ERROR: Failed to enable multi-cluster services. Exiting."; exit 1; }
echo "Multi-cluster services enabled."

# 6. Enable the multi-cluster gateway controller (Fleet Ingress)
# This deploys the Fleet Ingress controller to the specified config-membership cluster.
echo "Enabling multi-cluster gateway controller (Fleet Ingress) with '$MEMBERSHIP1_NAME' as config membership..."
gcloud container fleet ingress enable \
    --config-membership=$MEMBERSHIP1_NAME \
    --location=$REGION1 \
    --project=$PROJECT_ID || { echo "ERROR: Failed to enable multi-cluster gateway controller. Exiting."; exit 1; }
echo "Multi-cluster gateway controller enabled."

echo ""
echo "Multi-cluster gateways and services setup complete."
echo "It may take some time for the Fleet Ingress controller to deploy and become ready."
echo "You can check the status using: gcloud container fleet ingress describe --project=$PROJECT_ID"
echo "And monitor the controller deployment in the '$CLUSTER1_NAME' cluster."