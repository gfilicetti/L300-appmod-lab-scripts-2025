#!/bin/bash

# This script creates a Cloud SQL for PostgreSQL instance as per the lab requirements.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1" # Using us-central1 as the default region.
INSTANCE_NAME="bank-of-anthos-db"
DB_VERSION="POSTGRES_14"

# --- Script Execution ---

echo "--- Task 2: Create a Cloud SQL Instance ---"
echo ""
echo "Creating Cloud SQL for PostgreSQL instance named '$INSTANCE_NAME' in region '$REGION'..."
echo "Database version: $DB_VERSION"
echo "This operation can take several minutes to complete."

gcloud sql instances create "$INSTANCE_NAME" \
    --database-version="$DB_VERSION" \
    --region="$REGION" \
    --project="$PROJECT_ID"

# Check the exit code of the gcloud command to confirm success
if [ $? -eq 0 ]; then
    echo ""
    echo "Cloud SQL instance '$INSTANCE_NAME' created successfully."
    echo "You can view the instance in the Cloud Console or by running:"
    echo "gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID"
else
    echo ""
    echo "Error: Failed to create Cloud SQL instance '$INSTANCE_NAME'." >&2
    exit 1
fi

echo "Script finished."