#!/bin/bash

# This script deploys the Bank of Anthos application to a GKE Autopilot cluster,
# overriding the default in-cluster PostgreSQL databases with a Cloud SQL instance.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
PROJECT_ID=$(gcloud config get-value project)
REGION="us-west1" # Region of the GKE Autopilot cluster and Cloud SQL instance
CLUSTER_NAME="cepf-autopilot-cluster"
CLOUD_SQL_INSTANCE_NAME="bank-of-anthos-db"
CLOUD_SQL_USER="boa-user"

# Generate a random password for the Cloud SQL user
# In a production environment, use a more secure method for password management.
CLOUD_SQL_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9_ | head -c 16)
echo "Generated Cloud SQL Password: $CLOUD_SQL_PASSWORD"

echo "--- Task 3: Deploy Bank of Anthos with Cloud SQL Backend ---"
echo ""

# 1. Clone the Bank of Anthos repository
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

# 2. Get GKE cluster credentials
echo "Getting credentials for GKE cluster '$CLUSTER_NAME'..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to get cluster credentials. Exiting."; exit 1; }

# 3. Create databases and user in Cloud SQL
echo "Creating 'accounts-db' and 'ledger-db' databases in Cloud SQL instance '$CLOUD_SQL_INSTANCE_NAME'..."
# Using || true to allow script to continue if databases already exist
gcloud sql databases create accounts-db --instance="$CLOUD_SQL_INSTANCE_NAME" --project="$PROJECT_ID" || true
gcloud sql databases create ledger-db --instance="$CLOUD_SQL_INSTANCE_NAME" --project="$PROJECT_ID" || true

echo "Creating Cloud SQL user '$CLOUD_SQL_USER'..."
# Using || true to allow script to continue if user already exists
gcloud sql users create "$CLOUD_SQL_USER" --host=% --password="$CLOUD_SQL_PASSWORD" \
    --instance="$CLOUD_SQL_INSTANCE_NAME" --project="$PROJECT_ID" || true

echo "Cloud SQL databases and user created/verified."

# 4. Get Cloud SQL instance connection name
echo "Retrieving Cloud SQL instance connection name..."
CLOUD_SQL_CONNECTION_NAME=$(gcloud sql instances describe "$CLOUD_SQL_INSTANCE_NAME" \
    --format="value(connectionName)" --project="$PROJECT_ID")

if [ -z "$CLOUD_SQL_CONNECTION_NAME" ]; then
    echo "ERROR: Could not retrieve Cloud SQL connection name. Exiting."
    exit 1
fi
echo "Cloud SQL Connection Name: $CLOUD_SQL_CONNECTION_NAME"

# 5. Create Kubernetes Secrets for Cloud SQL credentials
echo "Creating Kubernetes secrets for Cloud SQL credentials..."
# Delete existing secrets if they exist to ensure fresh creation
kubectl delete secret cloudsql-db-credentials --ignore-not-found -n default
kubectl delete secret cloudsql-instance-credentials --ignore-not-found -n default

kubectl create secret generic cloudsql-db-credentials \
    --from-literal=username="$CLOUD_SQL_USER" \
    --from-literal=password="$CLOUD_SQL_PASSWORD" \
    -n default || { echo "ERROR: Failed to create cloudsql-db-credentials secret. Exiting."; exit 1; }

kubectl create secret generic cloudsql-instance-credentials \
    --from-literal=connection-name="$CLOUD_SQL_CONNECTION_NAME" \
    -n default || { echo "ERROR: Failed to create cloudsql-instance-credentials secret. Exiting."; exit 1; }

echo "Kubernetes secrets created."

# 6. Deploy Bank of Anthos application with Cloud SQL configuration using Kustomize
echo "Deploying Bank of Anthos application with Cloud SQL backend..."
kubectl apply -k ./bank-of-anthos || { echo "ERROR: Failed to deploy Bank of Anthos. Exiting."; exit 1; }

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

# --- Cleanup ---
# Navigate back to the original directory before cleaning up the cloned repo
cd ../../..
echo "Cleaning up cloned Bank of Anthos repository..."
rm -rf bank-of-anthos

echo "Script finished."