#!/bin/bash

# This script creates a GKE Autopilot cluster as per the lab requirements.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1" # Using us-central1 as the default region.
CLUSTER_NAME="cepf-autopilot-cluster"

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

echo "Script finished."

