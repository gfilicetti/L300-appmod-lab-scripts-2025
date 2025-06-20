#! /bin/bash
# enable all APIs needed in the lab
gcloud services enable "compute.googleapis.com"
gcloud services enable "container.googleapis.com"
gcloud services enable "cloudresourcemanager.googleapis.com"
gcloud services enable "monitoring.googleapis.com"
gcloud services enable "workstations.googleapis.com"
gcloud services enable "artifactregistry.googleapis.com"
gcloud services enable "clouddeploy.googleapis.com"

