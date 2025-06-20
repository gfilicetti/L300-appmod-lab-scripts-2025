#! /bin/bash

# variables
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
SERVICE_NAME="cepf-prod-service"  # Assuming you want to configure the prod service
FRONTEND_NAME="cepf-frontend"

# Configure the load balancer for the Cloud Run app

# 1. Restrict Ingress to Internal and Cloud Load Balancing
echo "Restricting ingress to Internal and Cloud Load Balancing..."
gcloud run services update $SERVICE_NAME \
    --ingress=internal-and-cloud-load-balancing \
    --region=$REGION \
    --project=$PROJECT_ID

# 2. Set up a global external HTTP load balancer
# This involves multiple steps:
# a) Create a health check
echo "Creating health check..."
gcloud compute health-checks create http cepf-health-check \
    --global \
    --use-serving-proxies

# b) Create a backend service
echo "Creating backend service..."
gcloud compute backend-services create cepf-backend-service \
    --load-balancing-scheme=EXTERNAL \
    --health-checks=cepf-health-check \
    --global

# c) Add the Cloud Run service as a backend to the backend service
echo "Adding Cloud Run service as backend..."
gcloud compute backend-services add-backend cepf-backend-service \
    --service=$SERVICE_NAME \
    --global \
    --region=$REGION

# d) Create a URL map to route requests to the backend service
echo "Creating URL map..."
gcloud compute url-maps create cepf-url-map --global \
    --default-service=cepf-backend-service

# e) Create a target HTTP proxy to route requests to the URL map
echo "Creating target HTTP proxy..."
gcloud compute target-http-proxies create cepf-http-proxy \
    --url-map=cepf-url-map \
    --global

# f) Create a global forwarding rule to route external traffic to the target proxy
echo "Creating forwarding rule..."
gcloud compute forwarding-rules create $FRONTEND_NAME \
    --target-http-proxy=cepf-http-proxy \
    --load-balancing-scheme=EXTERNAL \
    --ports=80 \
    --global

# 3. Get and display the Load Balancer IP address (for verification)
LB_IP=$(gcloud compute forwarding-rules describe $FRONTEND_NAME --global --format="value(IPAddress)")
echo "Load Balancer IP Address: $LB_IP"

# Verification (Manual): Access the application using the IP address
echo "Access the application in your browser using the IP address: http://$LB_IP"
