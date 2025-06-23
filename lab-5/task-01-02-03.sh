#!/bin/bash

# This script creates a GKE Autopilot cluster, Cloud SQL Postgres DB and deploys Bank of Anthos as per the lab requirements.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="cepf-autopilot-cluster"
# Qwiklabs will give you a region to use in the instructions once the environment is provisioned. Use that region here.
REGION="us-west1" # use Region given to you by qwiklabs
DB_REGION=$REGION
NAMESPACE="default"

# --- Script Execution ---

echo "--- Task 1: Create a GKE Autopilot Cluster ---"
echo ""
echo "Creating GKE Autopilot cluster named '$CLUSTER_NAME' in region '$REGION'..."
echo "This operation can take several minutes to complete."

gcloud container clusters create-auto "$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID"

# Check the exit code of the gcloud command to confirm success
if [ $? -eq 0 ]; then
    echo ""
    echo "GKE Autopilot cluster '$CLUSTER_NAME' created successfully."
    echo "You can verify its status in the Google Cloud Console or by running:"
    echo "gcloud container clusters list --filter=\"name=$CLUSTER_NAME\""
else
    echo ""
    echo "Error: Failed to create GKE Autopilot cluster '$CLUSTER_NAME'." >&2
    exit 1
fi

# Clone the Bank of Anthos repository
echo "Cloning Bank of Anthos repository..."
if [ -d "bank-of-anthos" ]; then
    echo "Bank of Anthos directory already exists. Skipping clone."
else
    git clone https://github.com/GoogleCloudPlatform/bank-of-anthos.git || { echo "ERROR: Failed to clone repository. Exiting."; exit 1; }
fi

BOA_DIR="bank-of-anthos/extras/cloudsql"
if [ ! -d "$BOA_DIR" ]; then
    echo "ERROR: Expected directory '$BOA_DIR' not found after cloning. Exiting."
    exit 1
fi

cd "$BOA_DIR" || { echo "ERROR: Failed to change directory to $BOA_DIR. Exiting."; exit 1; }

# run workload identity setup
# echo "Running Workload Identity Setup..."
# ./setup_workload_identity.sh

# create cloud sql instance
echo "Running Cloud SQL Instance Setup..."
./create_cloudsql_instance.sh

# Create a Cloud SQL admin demo secret in your GKE cluster. This gives your in-cluster Cloud SQL client a username and password to access Cloud SQL.
INSTANCE_NAME='bank-of-anthos-db'
INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME --format='value(connectionName)')

kubectl create secret -n $NAMESPACE generic cloud-sql-admin \
  --from-literal=username=admin --from-literal=password=admin \
  --from-literal=connectionName=$INSTANCE_CONNECTION_NAME

# Deploy Bank of Anthos to your cluster. Each backend Deployment (userservice, contacts, transactionhistory, balancereader, and ledgerwriter) is configured with a Cloud SQL Proxy sidecar container. Cloud SQL Proxy provides a secure TLS connection between the backend GKE pods and your Cloud SQL instance.
kubectl apply -n $NAMESPACE -f ./kubernetes-manifests/config.yaml
kubectl apply -n $NAMESPACE -f ./populate-jobs
kubectl apply -n $NAMESPACE -f ./kubernetes-manifests

# Wait a few minutes for all the pods to be RUNNING. (Except for the two populate- Jobs. They should be marked 0/3 - Completed when they finish successfully.)

echo "Script finished."

