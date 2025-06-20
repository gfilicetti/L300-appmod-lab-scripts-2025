#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)") 
REGION=us-central1
APP_CODE_URI="gs://cloud-training/cepf/cepf023/cepf023-app-code.zip"
REPO_NAME="cepf-repo"
SERVICE_ACCOUNT=$PROJECT_NUMBER-compute@developer.gserviceaccount.com # Construct service account email

# Use Cloud Build to build a container application

# 0. Grant permissions to the default service account
echo "Granting storage.objects.get access to the default Compute Engine service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/storage.objectViewer"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/artifactregistry.writer"

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
