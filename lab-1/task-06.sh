#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
REPO_NAME="cepf-repo"
PIPELINE_NAME="cepf-run-app-pipeline"
APP_CODE_DIR="app-code"
RELEASE_NAME="cepf-release-v2" 

# Promote the release to the production environment once the app passes verification

# 1. Promote the release to cepf-prod-service
echo "Promoting release $RELEASE_NAME to cepf-prod-service..."
gcloud deploy releases promote \
    --release $RELEASE_NAME \
    --delivery-pipeline=$PIPELINE_NAME \
    --region=$REGION \
    --project=$PROJECT_ID

# 2. Wait for service readiness before setting IAM (for cepf-dev-service)
echo "Waiting for cepf-dev-service to be ready... Sleep 1 minute..."
sleep 60

# 3. Allow unauthenticated invocations on cepf-prod-service
echo "Allowing unauthenticated invocations on cepf-prod-service..."
gcloud run services add-iam-policy-binding cepf-prod-service \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --region=$REGION \
    --project=$PROJECT_ID

# 4. Get and display the URL for cepf-prod-service (for verification)
SERVICE_URL=$(gcloud run services describe cepf-prod-service --region=$REGION --format='value(status.url)')
echo "CEPF Prod Service URL: $SERVICE_URL"

# Verification Step (Manual - uncomment to automatically open)
# if [[ "$SERVICE_URL" != "" ]]; then
#   echo "Opening CEPF Prod Service in browser..."
#   open "$SERVICE_URL"  # This command opens the URL in your default browser (macOS specific)
#   # For other OS, use:
#   # xdg-open "$SERVICE_URL" (Linux)
#   # start "$SERVICE_URL" (Windows)
# fi

