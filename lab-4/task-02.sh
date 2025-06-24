#!/bin/bash

# This script uses Google Cloud Deploy to deploy an application to two GKE clusters
# in different regions.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
PROJECT_ID=$(gcloud config get-value project)
# NOTE: Qwiklabs will give you a region to use in the instructions once the environment is provisioned. Use that region here.
REGION1="us-east4" # Lab start region / location of the first cluster
ZONE1="$REGION1-c"
REGION2="europe-west4"    # Location of the second cluster
ZONE2="$REGION2-b"

# NOTE: Update with the names of the pre-existing GKE clusters
CLUSTER1_NAME="cepf-gke-cluster-1"
CLUSTER2_NAME="cepf-gke-cluster-2"

# Artifact Registry and Image details (from previous step)
REPO_NAME="cepf-app-mod-repo"
IMAGE_NAME="whereami-app"
IMAGE_URI="$REGION1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME"

# Cloud Deploy resource names
PIPELINE_NAME="cepf-gke-pipeline"
RELEASE_NAME="gke-release-001"

# --- Script Execution ---

# 1. Create Kubernetes manifest (k8s-manifest.yaml)
# This defines the application to be deployed.
echo "Creating Kubernetes manifest (k8s-manifest.yaml)..."
cat <<EOF > k8s-manifest.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: store
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: store
  namespace: store
spec:
  replicas: 2
  selector:
    matchLabels:
      app: store
      version: v1
  template:
    metadata:
      labels:
        app: store
        version: v1
    spec:
      containers:
      - name: whereami
        image: $IMAGE_URI
        ports:
          - containerPort: 8080
EOF

# 2. Create Skaffold configuration (skaffold.yaml)
# This tells Cloud Deploy how to deploy the manifest.
echo "Creating Skaffold configuration (skaffold.yaml)..."
cat <<EOF > skaffold.yaml
apiVersion: skaffold/v4beta7
kind: Config
metadata:
  name: cepf-gke-app
manifests:
  rawYaml:
    - k8s-manifest.yaml
deploy:
  kubectl: {}
profiles:
- name: dev
- name: prod
EOF

# 3. Create Cloud Deploy pipeline definition (delivery-pipeline.yaml)
# This defines the deployment targets and the sequence of deployment.
echo "Creating Cloud Deploy pipeline definition (delivery-pipeline.yaml)..."
cat <<EOF > delivery-pipeline.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: $PIPELINE_NAME
description: "GKE multi-region delivery pipeline"
serialPipeline:
  stages:
  - targetId: $CLUSTER1_NAME-target
    profiles: ["dev"]
  - targetId: $CLUSTER2_NAME-target
    profiles: ["prod"]
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: $CLUSTER1_NAME-target
description: "GKE Cluster 1 in $REGION1"
gke:
  cluster: projects/$PROJECT_ID/locations/$ZONE1/clusters/$CLUSTER1_NAME
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: $CLUSTER2_NAME-target
description: "GKE Cluster 2 in $REGION2"
gke:
  cluster: projects/$PROJECT_ID/locations/$ZONE2/clusters/$CLUSTER2_NAME
EOF

# 4. Apply the delivery pipeline to Google Cloud Deploy
echo "Applying the delivery pipeline in region $REGION1..."
gcloud deploy apply \
  --file=delivery-pipeline.yaml \
  --region=$REGION1 \
  --project=$PROJECT_ID

# 5. Create a release to start the deployment
# This will automatically deploy to the first target in the pipeline.
echo "Creating release '$RELEASE_NAME' to initiate deployment..."
gcloud deploy releases create $RELEASE_NAME \
  --delivery-pipeline=$PIPELINE_NAME \
  --region=$REGION1 \
  --skaffold-file=skaffold.yaml \
  --source=. \
  --project=$PROJECT_ID

echo "Deployment to the first cluster ($CLUSTER1_NAME) has started."
echo "You can monitor the progress here:"
echo "https://console.cloud.google.com/deploy/delivery-pipelines/$REGION1/$PIPELINE_NAME/releases?project=$PROJECT_ID"
echo ""

echo "Wait for the rollout to the first target to complete successfully."
read -p "Once the first stage is complete, press [Enter] to promote the release to the second cluster..."

# 6. Promote the release to the next stage
echo "Promoting release '$RELEASE_NAME' to the second target ($CLUSTER2_NAME)..."
gcloud deploy releases promote \
  --release=$RELEASE_NAME \
  --delivery-pipeline=$PIPELINE_NAME \
  --region=$REGION1 \
  --project=$PROJECT_ID

echo "Promotion initiated. The application will now be deployed to $CLUSTER2_NAME."
echo "Script finished."
