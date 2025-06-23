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

# 2. Clone the Bank of Anthos repository if it doesn't exist
echo "Cloning Bank of Anthos repository..."
if [ -d "bank-of-anthos" ]; then
    echo "Bank of Anthos directory already exists. Skipping clone."
else
    git clone https://github.com/GoogleCloudPlatform/bank-of-anthos.git || { echo "ERROR: Failed to clone repository. Exiting."; exit 1; }
fi

LOADGEN_MANIFEST="bank-of-anthos/kubernetes-manifests/loadgenerator.yaml"
if [ ! -f "$LOADGEN_MANIFEST" ]; then
    echo "ERROR: Expected manifest '$LOADGEN_MANIFEST' not found. Exiting."
    exit 1
fi

# 3. Update the loadgenerator manifest to increase user load
echo "Updating '$LOADGEN_MANIFEST' to increase simulated USERS from 5 to 100..."
# Using a specific sed command to find the 'USERS' env var and replace the value on the next line.
# This is safer than a simple string replacement. The -i'' is for macOS compatibility.
sed -i'' -e '/- name: USERS/{n;s/value: "5"/value: "100"/;}' "$LOADGEN_MANIFEST"

echo "Manifest updated. Applying changes to the cluster..."

# 4. Apply the updated manifest to the cluster
kubectl apply -f "$LOADGEN_MANIFEST" || { echo "ERROR: Failed to apply updated loadgenerator manifest. Exiting."; exit 1; }

echo "Load generator has been updated to simulate 100 users."
echo ""

# 5. Guide user on how to observe the scaling
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