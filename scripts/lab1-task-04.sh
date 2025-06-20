#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
REPO_NAME="cepf-repo"
PIPELINE_NAME="cepf-run-app-pipeline"

# Use Google Cloud Deploy to deploy an application to Cloud Run

# 1. Create Skaffold configuration (skaffold.yaml)
cat <<EOF > skaffold.yaml
apiVersion: skaffold/v4beta7
kind: Config
metadata:
  name: cepf-run-app
build:
  artifacts:
  - image: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app
deploy:
  cloudrun:
    regions: [$REGION]
    projectid: $PROJECT_ID
EOF

# 2. Create service definition files
# cepf-dev-service.yaml
cat <<EOF > cepf-dev-service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: cepf-dev-service
spec:
  template:
    spec:
      containers:
      - image: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app
EOF

# cepf-prod-service.yaml
cat <<EOF > cepf-prod-service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: cepf-prod-service
spec:
  template:
    spec:
      containers:
      - image: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app
EOF

# 3. Create Google Cloud Deploy delivery pipeline
gcloud deploy apply --file=deploy_pipeline.yaml --region=$REGION --project=$PROJECT_ID <<EOF
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: $PIPELINE_NAME
  labels:
    managed-by: gcloud
    skaffold-version: 2.10.0
    cli-version: 426.0.0
    cli-core-version: 2023.03.28
    config-controller-version: 1.11.0
    api-version: v1
spec:
  serialPipeline:
    stages:
    - targetId: cepf-dev-service
      profiles: []
    - targetId: cepf-prod-service
      profiles: []
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: cepf-dev-service
  labels:
    managed-by: gcloud
spec:
  run:
    location: projects/$PROJECT_ID/locations/$REGION
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: cepf-prod-service
  labels:
    managed-by: gcloud
spec:
  run:
    location: projects/$PROJECT_ID/locations/$REGION
EOF

# 4. Instantiate delivery pipeline with a release
gcloud deploy releases create cepf-release \
    --delivery-pipeline=$PIPELINE_NAME \
    --region=$REGION \
    --images=cepf-app=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app \
    --skaffold-file=skaffold.yaml \
    --project=$PROJECT_ID

# 5. Allow unauthenticated invocations on cepf-dev-service
echo "Allowing unauthenticated invocations on cepf-dev-service..."
gcloud run services add-iam-policy-binding cepf-dev-service \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --region=$REGION \
    --project=$PROJECT_ID

# 6. Get and display the URL for cepf-dev-service (for verification)
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