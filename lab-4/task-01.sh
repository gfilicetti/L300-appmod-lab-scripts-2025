#!/bin/bash

# Variables
PROJECT_ID=$(gcloud config get-value project)
REGION1="us-central1"
REPO_NAME="cepf-app-mod-repo"
IMAGE_NAME="whereami-app"
GIT_REPO="https://github.com/GoogleCloudPlatform/kubernetes-engine-samples.git"
GIT_DIR="kubernetes-engine-samples/quickstarts/whereami"

# Task 1: Build a container application with Cloud Build

# 1. Clone the repository
echo "Cloning the repository..."
git clone $GIT_REPO
cd $GIT_DIR || exit 1

# 2. Create Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION1 \
    --project=$PROJECT_ID

# 3. Build and push the Docker image
echo "Building and pushing the Docker image..."
gcloud builds submit \
    --tag "$REGION1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME" \
    --project=$PROJECT_ID \
    --timeout="10m"  # Add a timeout to prevent indefinite builds

echo "Container image built and pushed to Artifact Registry."

# Optional: Clean up (remove cloned repo)
# cd ..
# rm -rf $GIT_DIR
