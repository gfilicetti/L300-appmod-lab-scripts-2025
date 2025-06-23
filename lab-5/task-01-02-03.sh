#!/bin/bash

# This script creates a GKE Autopilot cluster, Cloud SQL Postgres DB and deploys Bank of Anthos as per the lab requirements.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
export PROJECT_ID=$(gcloud config get-value project)
export CLUSTER_NAME="cepf-autopilot-cluster"
# Qwiklabs will give you a region to use in the instructions once the environment is provisioned. Use that region here.
export REGION="us-central1" # use Region given to you by qwiklabs
export DB_REGION=$REGION
export NAMESPACE="default"

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
echo "Running Workload Identity Setup..."
./setup_workload_identity.sh

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

echo "Bank of Anthos application deployment initiated. Waiting for services to be ready..."

# 7. Wait for the frontend service to get an external IP
echo "Waiting for frontend service to get an external IP address... (This may take a few minutes)"
FRONTEND_IP=""
while [ -z "$FRONTEND_IP" ]; do
  echo "Checking for frontend IP..."
  FRONTEND_IP=$(kubectl get service frontend -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  [ -z "$FRONTEND_IP" ] && sleep 10
done

echo "Bank of Anthos frontend accessible at: http://$FRONTEND_IP"
echo ""

# 8. Validate the deployment
echo "--- Validating Deployment ---"
echo "Attempting to curl the frontend service..."
curl_output=$(curl -s -o /dev/null -w "%{http_code}" http://$FRONTEND_IP)
if [ "$curl_output" -eq 200 ]; then
    echo "Frontend service is reachable (HTTP 200 OK)."
else
    echo "Warning: Frontend service returned HTTP $curl_output. It might still be initializing."
fi

echo ""
echo "To validate the full deployment:"
echo "1. Open your web browser and navigate to: http://$FRONTEND_IP"
echo "2. Log in with the following credentials:"
echo "   Username: testuser"
echo "   Password: password"
echo "3. Verify that you can see account balances and perform transactions."
echo ""

echo "Script finished."

