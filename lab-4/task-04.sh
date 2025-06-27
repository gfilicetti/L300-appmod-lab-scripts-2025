#!/bin/bash

# This script deploys a multi-cluster Gateway and HTTPRoute to expose an
# application running across two GKE clusters with path-based routing.

# --- Configuration ---
# Ensure these variables are set correctly for your environment.
# These should be consistent with the values used in previous tasks.
PROJECT_ID=$(gcloud config get-value project)
# NOTE: Qwiklabs will give you a region to use in the instructions once the environment is provisioned. Use that region here.
REGION1="us-central1" # Lab start region / location of the first cluster
ZONE1="$REGION1-c" # the zone for gke cluster 1
REGION2="europe-west4"    # Location of the second cluster
ZONE2="$REGION2-c" # the zone for gke cluster 2

# IMPORTANT: Update with the names of your GKE clusters, consistent with task-02.sh
CLUSTER1_NAME="cepf-gke-cluster-1"
CLUSTER2_NAME="cepf-gke-cluster-2"

# --- Script Execution ---

echo "--- Task 4: Leverage Multi-Cluster Services and Gateways ---"
echo ""

# --- Step 1: Expose and Export Services in Each Cluster ---
# To route traffic to a specific cluster, we need to create distinct services
# and export them. We will create a generic 'store' service for default load
# balancing and region-specific services for targeted routing.

echo "Creating Service and ServiceExport manifests for ${CLUSTER1_NAME}..."
cat <<EOF > services-cluster1.yaml
apiVersion: v1
kind: Service
metadata:
  name: store-region1
  namespace: store
spec:
  selector:
    app: store
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: net.gke.io/v1
kind: ServiceExport
metadata:
  name: store-region1
  namespace: store
---
apiVersion: v1
kind: Service
metadata:
  name: store
  namespace: store
spec:
  selector:
    app: store
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: net.gke.io/v1
kind: ServiceExport
metadata:
  name: store
  namespace: store
EOF

echo "Creating Service and ServiceExport manifests for ${CLUSTER2_NAME}..."
cat <<EOF > services-cluster2.yaml
apiVersion: v1
kind: Service
metadata:
  name: store-region2
  namespace: store
spec:
  selector:
    app: store
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: net.gke.io/v1
kind: ServiceExport
metadata:
  name: store-region2
  namespace: store
---
apiVersion: v1
kind: Service
metadata:
  name: store
  namespace: store
spec:
  selector:
    app: store
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: net.gke.io/v1
kind: ServiceExport
metadata:
  name: store
  namespace: store
EOF

echo "Applying service configurations to clusters..."
gcloud container clusters get-credentials "${CLUSTER1_NAME}" --zone "${ZONE1}" --project "${PROJECT_ID}"
kubectl apply -f services-cluster1.yaml

gcloud container clusters get-credentials "${CLUSTER2_NAME}" --zone "${ZONE2}" --project "${PROJECT_ID}"
kubectl apply -f services-cluster2.yaml

echo "Services and ServiceExports deployed to both clusters."

# --- Step 2: Deploy Multi-Cluster Gateway and HTTPRoute ---
# These resources are deployed to the fleet's config cluster (cluster 1).

echo "Creating Gateway and HTTPRoute manifests..."
cat <<EOF > gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: external-http
  namespace: store
spec:
  gatewayClassName: gke-l7-gxlb-mc
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: All
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: store-route
  namespace: store
spec:
  parentRefs:
  - name: external-http
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /region-1
    backendRefs:
    - name: store-region1
      group: net.gke.io
      kind: Service
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /region-2
    backendRefs:
    - name: store-region2
      group: net.gke.io
      kind: Service
      port: 8080
  - backendRefs:
    - name: store
      group: net.gke.io
      kind: Service
      port: 8080
EOF

echo "Applying Gateway and HTTPRoute to config cluster '${CLUSTER1_NAME}'..."
gcloud container clusters get-credentials "${CLUSTER1_NAME}" --zone "${ZONE1}" --project "${PROJECT_ID}"
kubectl apply -f gateway.yaml

# --- Step 3: Wait for Gateway IP and Validate ---

echo "Waiting for Gateway to be assigned an external IP address... (This may take several minutes)"
VIP=""
while [ -z "$VIP" ]; do
  echo "Checking for IP..."
  VIP=$(kubectl get gateways.gateway.networking.k8s.io external-http -o=jsonpath='{.status.addresses[0].value}' --namespace store 2>/dev/null)
  [ -z "$VIP" ] && sleep 15
done

echo "Gateway provisioned with IP Address: $VIP"
echo ""
echo "--- Validating Deployment ---"
echo "Sending traffic to /region-1 (should be served by ${CLUSTER1_NAME}):"
curl -s http://$VIP/region-1 | grep "cluster_name"
echo ""

echo "Sending traffic to /region-2 (should be served by ${CLUSTER2_NAME}):"
curl -s http://$VIP/region-2 | grep "cluster_name"
echo ""

echo "Sending traffic to / (should be served by either cluster):"
curl -s http://$VIP/ | grep "cluster_name"
echo ""

# --- Cleanup ---
#rm services-cluster1.yaml services-cluster2.yaml gateway.yaml

echo "Script finished."