#!/bin/bash

# This script configures Horizontal Pod Autoscaling (HPA) for the
# frontend and userservice deployments in the Bank of Anthos application.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
# These should be consistent with the values used in previous tasks.
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1" # Region of the GKE Autopilot cluster
CLUSTER_NAME="cepf-autopilot-cluster"

# --- Script Execution ---

echo "--- Task 4: Configure Horizontal Pod Autoscaling ---"
echo ""

# 1. Get GKE cluster credentials
# This ensures kubectl is configured to communicate with the correct cluster.
echo "Getting credentials for GKE cluster '$CLUSTER_NAME'..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to get cluster credentials. Exiting."; exit 1; }

echo ""

# 2. Configure HPA for the 'frontend' deployment
echo "Configuring HPA for the 'frontend' deployment..."
echo "  - Target CPU: 50%"
echo "  - Min Replicas: 1"
echo "  - Max Replicas: 10"
kubectl autoscale deployment frontend --cpu-percent=50 --min=1 --max=10 -n default || { echo "ERROR: Failed to apply HPA to 'frontend'. Exiting."; exit 1; }
echo "HPA for 'frontend' configured successfully."
echo ""

# 3. Configure HPA for the 'userservice' deployment
echo "Configuring HPA for the 'userservice' deployment..."
echo "  - Target CPU: 50%"
echo "  - Min Replicas: 1"
echo "  - Max Replicas: 10"
kubectl autoscale deployment userservice --cpu-percent=50 --min=1 --max=10 -n default || { echo "ERROR: Failed to apply HPA to 'userservice'. Exiting."; exit 1; }
echo "HPA for 'userservice' configured successfully."
echo ""

# 4. Verify HPA configuration
echo "--- Verifying HPA Configuration ---"
echo "Listing HorizontalPodAutoscalers in the 'default' namespace:"
kubectl get hpa -n default
echo ""
echo "Note: The 'TARGETS' column may show '<unknown>/50%' initially. This is normal and will update once metrics are collected."
echo "Script finished."