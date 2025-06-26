#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
# NOTE: Qwiklabs will give you a region to use in the instructions once the environment is provisioned. Use that region here.
REGION="us-east4" # Lab start region / location of the first cluster
REPO_NAME="cepf-app-mod-repo"
IMAGE_NAME="whereami-app"
GIT_REPO="https://github.com/GoogleCloudPlatform/kubernetes-engine-samples.git"
GIT_DIR="kubernetes-engine-samples/quickstarts/whereami"

# Task 1: Build a container application with Cloud Build

# 0. Create a Fleet
echo "Creating a fleet for the project..."
# This command creates a fleet with the display name 'fleet' if one doesn't exist.
# '|| true' ensures the script doesn't fail if the fleet has already been created.
gcloud container fleet create --display-name="fleet" --project=$PROJECT_ID || true

# 1. Clone the repository
echo "Cloning the repository..."
git clone $GIT_REPO
cd $GIT_DIR || exit 1

# 2. Create Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --project=$PROJECT_ID

# 3. Build and push the Docker image
echo "Building and pushing the Docker image..."
gcloud builds submit \
    --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME" \
    --project=$PROJECT_ID \
    --timeout="10m"  # Add a timeout to prevent indefinite builds

echo "Container image built and pushed to Artifact Registry."