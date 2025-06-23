#!/bin/bash

# This script load tests the Bank of Anthos application by updating the
# loadgenerator deployment to increase the number of simulated users.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
# These should be consistent with the values used in previous tasks.
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1" # Region of the GKE Autopilot cluster
CLUSTER_NAME="cepf-autopilot-cluster"

# --- Script Execution ---

echo "--- Task 5: Load Test Your Workload ---"
echo ""

# 1. Get GKE cluster credentials
# This ensures kubectl is configured to communicate with the correct cluster.
echo "Getting credentials for GKE cluster '$CLUSTER_NAME'..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to get cluster credentials. Exiting."; exit 1; }

# 2. Update the loadgenerator deployment to increase user load
echo "Updating the 'loadgenerator' deployment to increase simulated USERS from 5 to 100..."
# We use 'kubectl set env' to directly modify the environment variable of the running deployment.
# This is more robust and idiomatic than modifying the source YAML file and reapplying it,
# which can cause errors if immutable fields like 'spec.selector' have changed between versions.
kubectl set env deployment/loadgenerator USERS=100 -n default || { echo "ERROR: Failed to update loadgenerator deployment. Exiting."; exit 1; }

echo "Load generator has been updated to simulate 100 users."
echo ""

# 3. Guide user on how to observe the scaling
echo "--- Observing Autoscaling ---"
echo "The increased load should trigger the Horizontal Pod Autoscalers for 'frontend' and 'userservice'."
echo "You can monitor the HPA status and pod scaling with the following commands:"
echo ""
echo "To watch the HPA status (look for TARGETS CPU % to increase and REPLICAS to go up):"
echo "  watch kubectl get hpa -n default"
echo ""
echo "To watch the pods being created:"
echo "  kubectl get pods -n default -w"
echo ""
echo "It may take a few minutes for the metrics to propagate and for new pods to be scheduled and started."

echo "Script finished."