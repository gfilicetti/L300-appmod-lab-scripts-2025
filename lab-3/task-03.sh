#!/bin/bash

# This script configures Workload Identity Federation post-cluster creation
# by linking a Kubernetes Service Account (KSA) to a Google Cloud IAM Service Account (GSA).

# --- Configuration ---
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="cepf-gke-cluster"
ZONE="us-west1-a" # Ensure this matches the zone used in lab-3/task-01.sh

# Workload Identity specific variables
GSA_NAME="my-workload-identity-gsa"
GSA_EMAIL="${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KSA_NAMESPACE="default" # Or any namespace where your app's KSA will reside
KSA_NAME="my-workload-identity-ksa"

# --- Script Execution ---

echo "--- Task 3: Configure Workload Identity Federation ---"
echo ""

# 1. Get GKE cluster credentials
echo "Step 1: Getting credentials for GKE cluster '$CLUSTER_NAME'..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to get cluster credentials. Exiting."; exit 1; }
echo ""

# 2. Create a Google Cloud IAM Service Account (GSA)
echo "Step 2: Creating Google Cloud IAM Service Account '$GSA_NAME'..."
gcloud iam service-accounts create "$GSA_NAME" \
    --display-name="GSA for Workload Identity Demo" \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to create GSA. Exiting."; exit 1; }
echo "GSA '$GSA_EMAIL' created."
echo ""

# 3. Grant the GSA necessary permissions (e.g., Storage Object Viewer for demo)
echo "Step 3: Granting 'roles/storage.objectViewer' to GSA '$GSA_EMAIL'..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$GSA_EMAIL" \
    --role="roles/storage.objectViewer" \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to grant role to GSA. Exiting."; exit 1; }
echo "Role granted to GSA."
echo ""

# 4. Create a Kubernetes Service Account (KSA)
echo "Step 4: Creating Kubernetes Service Account '$KSA_NAME' in namespace '$KSA_NAMESPACE'..."
kubectl create serviceaccount "$KSA_NAME" --namespace "$KSA_NAMESPACE" || { echo "ERROR: Failed to create KSA. Exiting."; exit 1; }
echo "KSA '$KSA_NAME' created."
echo ""

# 5. Grant the GSA the 'roles/iam.workloadIdentityUser' role to the KSA
# This allows the KSA to impersonate the GSA.
echo "Step 5: Granting 'roles/iam.workloadIdentityUser' to GSA '$GSA_EMAIL' for KSA '$KSA_NAMESPACE/$KSA_NAME'..."
gcloud iam service-accounts add-iam-policy-binding "$GSA_EMAIL" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${KSA_NAMESPACE}/${KSA_NAME}]" \
    --role="roles/iam.workloadIdentityUser" \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to bind KSA to GSA. Exiting."; exit 1; }
echo "Workload Identity binding created."
echo ""

# 6. Annotate the KSA to link it to the GSA
echo "Step 6: Annotating KSA '$KSA_NAME' with GSA '$GSA_EMAIL'..."
kubectl annotate serviceaccount "$KSA_NAME" \
    --namespace "$KSA_NAMESPACE" \
    "iam.gke.io/gcp-service-account=${GSA_EMAIL}" || { echo "ERROR: Failed to annotate KSA. Exiting."; exit 1; }
echo "KSA annotated."
echo ""

# --- Verification ---
echo "--- Verification: Deploying a test pod to verify Workload Identity ---"
echo "Creating a test pod that uses KSA '$KSA_NAME' and attempts to list GCS buckets..."

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: workload-identity-test-pod
  namespace: ${KSA_NAMESPACE}
spec:
  serviceAccountName: ${KSA_NAME}
  containers:
  - name: gcloud-sdk
    image: google/cloud-sdk:latest
    command: ["/bin/bash", "-c", "gcloud auth list && gsutil ls && sleep 3600"]
    # sleep 3600 keeps the pod running for inspection
  restartPolicy: Never
EOF

echo "Test pod 'workload-identity-test-pod' deployed. It will try to list GCS buckets."
echo "You can check its logs to see if it successfully listed buckets:"
echo "  kubectl logs -f workload-identity-test-pod -n ${KSA_NAMESPACE}"
echo "If it lists your project's GCS buckets, Workload Identity is working!"
echo ""

# --- Cleanup Instructions ---
echo "--- Cleanup  Instructions ---"
echo "To clean up the resources created by this script, run the following commands:"
echo "1. Delete the test pod:"
echo "   kubectl delete pod workload-identity-test-pod -n ${KSA_NAMESPACE}"
echo "2. Delete the Kubernetes Service Account:"
echo "   kubectl delete serviceaccount ${KSA_NAME} -n ${KSA_NAMESPACE}"
echo "3. Remove the IAM policy binding (this is crucial for security):"
echo "   gcloud iam service-accounts remove-iam-policy-binding ${GSA_EMAIL} \\"
echo "       --member=\"serviceAccount:${PROJECT_ID}.svc.id.goog[${KSA_NAMESPACE}/${KSA_NAME}]\" \\"
echo "       --role=\"roles/iam.workloadIdentityUser\" \\"
echo "       --project=\"${PROJECT_ID}\""
echo "4. Remove the GSA's role binding (if you don't need it for other purposes):"
echo "   gcloud projects remove-iam-policy-binding ${PROJECT_ID} \\"
echo "       --member=\"serviceAccount:${GSA_EMAIL}\" \\"
echo "       --role=\"roles/storage.objectViewer\" \\"
echo "       --project=\"${PROJECT_ID}\""
echo "5. Delete the Google Cloud IAM Service Account:"
echo "   gcloud iam service-accounts delete ${GSA_EMAIL} --project=\"${PROJECT_ID}\""
echo ""

echo "Script finished."