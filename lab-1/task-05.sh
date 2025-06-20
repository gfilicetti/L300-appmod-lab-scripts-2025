#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
REPO_NAME="cepf-repo"
PIPELINE_NAME="cepf-run-app-pipeline"
APP_CODE_DIR="app-code/cepf023-app-code"
OLD_RELEASE_NAME="cepf-release" 
RELEASE_NAME="cepf-release-v2" 

# Fix any issues and redeploy the app

# 1. Update Dockerfile
echo "Updating Dockerfile to use index_v2.html..."
# This assumes your Dockerfile copies index.html.  Adjust if needed.
# This sed command replaces "index.html" with "index_v2.html" in the COPY instruction.
# BE CAREFUL: This could break your Dockerfile if it contains other COPY commands.
# Consider a more specific replacement if necessary.
if [[ -f "$APP_CODE_DIR/Dockerfile" ]]; then
    sed -i 's/index_v1.html/index_v2.html/' "$APP_CODE_DIR/Dockerfile"
else
    echo "Error: Dockerfile not found in $APP_CODE_DIR. Please ensure the path is correct and you are in the right directory"
    exit 1
fi

# 2. Build and push the new image
echo "Building and pushing new Docker image..."
pushd $APP_CODE_DIR || exit
gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app --project=$PROJECT_ID
popd || exit

# 3. Abandon the older release (Optional, but recommended)
#  To find the release name, you might need to list releases:
#  gcloud deploy releases list --delivery-pipeline=$PIPELINE_NAME --region=$REGION --project=$PROJECT_ID
echo "Abandoning older release: $OLD_RELEASE_NAME"
gcloud deploy releases abandon $OLD_RELEASE_NAME --delivery-pipeline=$PIPELINE_NAME --region=$REGION --project=$PROJECT_ID

# 4. Create a new release
echo "Creating a new release to deploy the updated image..."
gcloud deploy releases create $RELEASE_NAME \
    --delivery-pipeline=$PIPELINE_NAME \
    --region=$REGION \
    --images=cepf-app=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app \
    --skaffold-file=skaffold.yaml \
    --project=$PROJECT_ID

# 5. Get and display the URL for cepf-dev-service (for verification)
SERVICE_URL=$(gcloud run services describe cepf-dev-service --region=$REGION --format='value(status.url)')
echo "CEPF Dev Service URL: $SERVICE_URL"

# Verification Step (Manual - uncomment to automatically open)
# if [[ "$SERVICE_URL" != "" ]]; then
#   echo "Opening CEPF Dev Service in browser..."
#   open "$SERVICE_URL"  # This command opens the URL in your default browser (macOS specific)
#   # For other OS, use:
#   # xdg-open "$SERVICE_URL" (Linux)
#   # start "$SERVICE_URL" (Windows)
# fi
