#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
REPO_NAME="cepf-repo"
PIPELINE_NAME="cepf-run-app-pipeline"

# Use Google Cloud Deploy to deploy an application to Cloud Run

# 1. Create Skaffold configuration (skaffold.yaml)
echo "Creating skaffold.yaml..."
cat <<EOF > skaffold.yaml
apiVersion: skaffold/v4beta7
kind: Config
metadata:
  name: cepf-run-app
build:
  artifacts:
  - image: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app
profiles:
  name: dev
  manifests:
    rawYaml:
    - cepf-dev-service.yaml
  name: prod
  manifests:
    rawYaml:
    - cepf-prod-service.yaml
EOF

# 2. Create service definition files
# cepf-dev-service.yaml
echo "Creating cepf-dev-service.yaml..."
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
echo "Creating cepf-prod-service.yaml..."
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

# 3. Create deploy_pipeline.yaml
echo "Creating deploy_pipeline.yaml..."
cat <<EOF > deploy_pipeline.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: $PIPELINE_NAME
serialPipeline:
  stages:
  - targetId: cepf-dev-service
    profiles: ["dev"]
  - targetId: cepf-prod-service
    profiles: ["prod"]
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: cepf-dev-service
run:
  location: projects/$PROJECT_ID/locations/$REGION
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: cepf-prod-service
run:
  location: projects/$PROJECT_ID/locations/$REGION
EOF

# 4. Create Google Cloud Deploy delivery pipeline
echo "Creating Google Cloud Deploy delivery pipeline..."
gcloud deploy apply --file=deploy_pipeline.yaml --region=$REGION --project=$PROJECT_ID

# 5. Instantiate delivery pipeline with a release
echo "Instantiating delivery pipeline with a release..."
gcloud deploy releases create cepf-release \
    --delivery-pipeline=$PIPELINE_NAME \
    --region=$REGION \
    --images=cepf-app=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cepf-app \
    --skaffold-file=skaffold.yaml \
    --project=$PROJECT_ID

# 6. Poll for service readiness before setting IAM (for cepf-dev-service)
echo "Waiting for cepf-dev-service to be ready..."
for i in {1..30}; do  # Try for up to 5 minutes (30 * 10 seconds)
  if gcloud run services describe cepf-dev-service --region=$REGION --project=$PROJECT_ID --format="value(status.conditions[?type=='Ready'].status)" | grep -q "True"; then
    echo "cepf-dev-service is ready."
    break
  else
    echo "Waiting... ($i/30)"
    sleep 10
  fi
done

# 7. Allow unauthenticated invocations on cepf-dev-service
echo "Allowing unauthenticated invocations on cepf-dev-service..."
gcloud run services add-iam-policy-binding cepf-dev-service \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --region=$REGION \
    --project=$PROJECT_ID

# 8. Get and display the URL for cepf-dev-service (for verification)
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