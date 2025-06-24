#!/bin/bash

# This script enables multi-cluster gateways and services for GKE clusters
# by registering them to a fleet and enabling fleet ingress.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
# These should be consistent with the values used in task-02.sh.
PROJECT_ID=$(gcloud config get-value project)
# NOTE: Qwiklabs will give you a region to use in the instructions once the environment is provisioned. Use that region here.
ZONE1="us-east4-c" # Lab start region / location of the first cluster
ZONE2="europe-west4-b"    # Location of the second cluster

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

# 2. Pre-requisite: Enable Gateway API on GKE clusters
# This is a crucial step as Fleet Ingress relies on the Gateway API.
# You must install the Gateway API CRDs on each cluster that will participate
# in the multi-cluster gateway.
echo "IMPORTANT: Before proceeding, ensure the Gateway API is enabled on your GKE clusters."
echo "This typically involves installing the Gateway API CRDs on each cluster."
echo "For example, for GKE clusters, you would run (check for the latest stable version):"
echo "  kubectl --context=gke_${PROJECT_ID}_${ZONE1}_${CLUSTER1_NAME} apply -k https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml"
echo "  kubectl --context=gke_${PROJECT_ID}_${ZONE2}_${CLUSTER2_NAME} apply -k https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml"
echo ""
echo "Wait for the Gateway API components to be ready on both clusters before continuing."
read -p "Press [Enter] to continue after ensuring Gateway API is enabled on your clusters..."

# 3. Register both clusters to the fleet
# Registering clusters to a fleet allows them to be managed centrally and enables fleet features.
echo "Registering GKE cluster '$CLUSTER1_NAME' to fleet with membership '$MEMBERSHIP1_NAME'..."
gcloud container fleet memberships register $MEMBERSHIP1_NAME \
    --gke-cluster=projects/$PROJECT_ID/locations/$ZONE1/clusters/$CLUSTER1_NAME \
    --enable-workload-identity \
    --project=$PROJECT_ID || { echo "ERROR: Failed to register $CLUSTER1_NAME. Exiting."; exit 1; }

echo "Registering GKE cluster '$CLUSTER2_NAME' to fleet with membership '$MEMBERS2_NAME'..."
gcloud container fleet memberships register $MEMBERS2_NAME \
    --gke-cluster=projects/$PROJECT_ID/locations/$ZONE2/clusters/$CLUSTER2_NAME \
    --enable-workload-identity \
    --project=$PROJECT_ID || { echo "ERROR: Failed to register $CLUSTER2_NAME. Exiting."; exit 1; }

echo "Clusters registered to the fleet."

# 4. Enable multi-cluster services (MCS)
# MCS allows services to be discovered and accessed across clusters in the fleet.
echo "Enabling multi-cluster services for the fleet..."
gcloud container fleet ingress enable-multicluster-services --project=$PROJECT_ID || { echo "ERROR: Failed to enable multi-cluster services. Exiting."; exit 1; }
echo "Multi-cluster services enabled."

# 5. Enable the multi-cluster gateway controller (Fleet Ingress)
# This deploys the Fleet Ingress controller to the specified config-membership cluster.
echo "Enabling multi-cluster gateway controller (Fleet Ingress) with '$MEMBERSHIP1_NAME' as config membership..."
gcloud container fleet ingress enable \
    --config-membership=$MEMBERSHIP1_NAME \
    --project=$PROJECT_ID || { echo "ERROR: Failed to enable multi-cluster gateway controller. Exiting."; exit 1; }
echo "Multi-cluster gateway controller enabled."

echo ""
echo "Multi-cluster gateways and services setup complete."
echo "It may take some time for the Fleet Ingress controller to deploy and become ready."
echo "You can check the status using: gcloud container fleet ingress describe --project=$PROJECT_ID"
echo "And monitor the controller deployment in the '$CLUSTER1_NAME' cluster."