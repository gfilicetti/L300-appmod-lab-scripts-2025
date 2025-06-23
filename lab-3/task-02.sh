#!/bin/bash

# This script outlines the steps to configure Policy Controller and Config Sync
# and test Anthos Config Management capabilities.  It includes verification
# steps where possible, but some actions require manual configuration in the
# Google Cloud Console.
# This script configures Policy Controller and Config Sync using gcloud and kubectl,
# and tests the Anthos Config Management capabilities.

# Variables (Update these with your actual values)
# --- Configuration ---
PROJECT_ID=$(gcloud config get-value project)
GKE_CLUSTER_NAME="cepf-gke-cluster"
GKE_CLUSTER_ZONE="us-central1-a"
CONFIG_SYNC_REPO="https://github.com/GoogleCloudPlatform/anthos-config-management-samples"
MEMBERSHIP_NAME="${GKE_CLUSTER_NAME}-membership"
POLICY_DIR="quickstart/config-sync"

# 1. Enable required APIs
echo "Step 1: Enabling Anthos API..."
gcloud services enable anthos.googleapis.com --project="$PROJECT_ID"
echo "API enabled."
echo ""

# 2. Create the fleet configuration file for Config Sync and Policy Controller
echo "Step 2: Creating fleet configuration file (config.yaml)..."
cat <<EOF > config.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
    sourceFormat: unstructured
    git:
      syncRepo: "$CONFIG_SYNC_REPO"
      syncBranch: main
      policyDir: "$POLICY_DIR"
      secretType: none
  policyController:
    enabled: true
    # Allows for mutation of resources
    referentialRulesEnabled: true
    # Installs a library of common policy templates
    templateLibraryInstalled: true
EOF
echo "Configuration file created."
echo ""

# 3. Apply the configuration to the cluster's fleet membership
echo "Step 3: Applying configuration to fleet membership '$MEMBERSHIP_NAME'..."
echo "This may take several minutes..."
gcloud beta container fleet config-management apply \
    --membership="$MEMBERSHIP_NAME" \
    --config=config.yaml \
    --project="$PROJECT_ID" || { echo "ERROR: Failed to apply fleet configuration. Exiting."; exit 1; }
echo "Fleet configuration applied."
echo ""

# 4. Get cluster credentials to use kubectl
echo "Step 4: Getting credentials for '$GKE_CLUSTER_NAME' to verify..."
gcloud container clusters get-credentials "$GKE_CLUSTER_NAME" --zone="$GKE_CLUSTER_ZONE" --project="$PROJECT_ID"
echo ""

# 5. Verify that the 'hello' namespace from the repo is synced
echo "Step 5: Verifying that the 'hello' namespace is synced by Config Sync..."
echo "Waiting for namespace 'hello' to be created..."
until kubectl get namespace hello > /dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo ""
echo "SUCCESS: Namespace 'hello' found."
kubectl get all -n hello
echo ""

# 6. Test the Policy Controller constraint (no-ext-services.yaml)
echo "Step 6: Testing the Policy Controller constraint that blocks external services..."
# The sample repo includes a constraint that prevents services of type LoadBalancer.
# We will attempt to create one to verify the policy is enforced.

echo "Creating a test service of type LoadBalancer (service.yaml)..."
cat <<EOF > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: test-external-service
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    # This selector doesn't need to match anything for the policy to be tested
    app: test-app
EOF

echo "Attempting to apply the forbidden service. This command is expected to fail."
# We redirect stderr to /dev/null to hide the expected error message for a cleaner output.
# The 'if !' condition checks for a non-zero exit code, which indicates failure (and thus success for our test).
if ! kubectl apply -f service.yaml 2> /dev/null; then
    echo "SUCCESS: Policy Controller correctly blocked the creation of the LoadBalancer service."
else
    echo "FAILURE: The LoadBalancer service was created, which means the policy is not being enforced."
    # Clean up the service if it was created
    kubectl delete -f service.yaml --ignore-not-found
fi
echo ""

# 7. Cleanup local files
echo "Step 7: Cleaning up local configuration files..."
rm config.yaml service.yaml
echo "Cleanup complete."
echo ""

echo "--- End of Script ---"
