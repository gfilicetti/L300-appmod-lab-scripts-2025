#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
APP_CODE_URI="gs://cloud-training/cepf/cepf023/cepf023-app-code.zip"
REPO_NAME="cepf-repo"

# Use Cloud Build to build a container application

# 1. Download application code
echo "Downloading application code..."
gsutil cp $APP_CODE_URI app-code.zip
unzip app-code.zip -d app-code
cd app-code/cepf023-app-code || exit

# 2. Create Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --project=$PROJECT_ID

# 3. Build and push with Cloud Build
echo "Building and pushing Docker image..."
gcloud builds submit \
    --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app \
    --project=$PROJECT_ID
