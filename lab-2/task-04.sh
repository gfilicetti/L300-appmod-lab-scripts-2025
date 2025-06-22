#!/bin/bash

# Variables
VM_NAME=lab-setup
ZONE=us-west1-a

# The issue: A misconfigured ConfigMap 
# Solution: Fix the file path to the pub key location

# Step 1. Log into the VM holding the application
echo "Logging into the management VM: $VM_NAME"
echo "Execute the commented out commands in this script"
gcloud compute ssh $VM_NAME --zone=$ZONE

# Step 2. Fix the error in config.yaml
# cd bank-of-anthos
# vi kubernetes-manifests/config.yaml
# 
# Change line 21 to read:
# PUB_KEY_PATH: "/tmp/.ssh/publickey"
# Save the file

# Step 3. Redeploy the app and check pod status
# kubectl -f ./kubernetes-manifests
# It will take several minutes for the pods to reset themselves

# Step 4. Check the status of all the pods
# kubectl get pods
# Make sure all the pods are running
