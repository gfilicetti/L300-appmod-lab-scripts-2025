#!/bin/bash

# This script provides guidance on using Log Analytics to identify issues
# with pods in a GKE Autopilot cluster.  It assumes you have already
# set up Log Analytics and are familiar with the gcloud command-line tool.

# NOTE: This script does NOT execute the queries directly. It provides
# the SQL queries you should run in the BigQuery console for your
# Log Analytics linked dataset.

# Replace with your project ID if not already set in gcloud config
# PROJECT_ID=$(gcloud config get-value project)
# if [[ -z "$PROJECT_ID" ]]; then
#   echo "Error: Project ID not set. Please set it using 'gcloud config set project <YOUR_PROJECT_ID>'"
#   exit 1
# fi
PROJECT_ID=$(gcloud config get-value project)

# Replace with your Log Analytics linked dataset ID
DATASET_ID="cepf_dataset"

# 1. Finding Errors in the Last Hour

echo "To find error messages from pods in the last hour, use the following SQL query in BigQuery:"
echo ""
echo "SELECT"
echo "    json_payload.kubernetes.pod_name,"
echo "    json_payload.message,"
echo "    timestamp"
echo "FROM"
echo "  \`$PROJECT_ID.global.\$BQ_DATASET_NAME.cloudaudit_googleapis_com_data_access\`"
echo "WHERE"
echo "  resource.labels.cluster_name = 'cepf-autopilot-cluster'"
echo "  AND json_payload.level = 'ERROR'"  # or 'error', case-sensitive depending on your app's logging
echo "  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)"
echo "ORDER BY"
echo "  timestamp DESC"
echo ";"
echo ""
echo "This query filters logs for:"
echo "  - Your specific GKE Autopilot cluster (replace cepf-autopilot-cluster)"
echo "  - Log entries with a 'level' of 'ERROR' (adjust if your app uses a different error indicator)."
echo "  - Logs within the last hour."
echo "It then displays the pod name, error message, and timestamp, ordered by the most recent logs."

# 2. Focusing on a Specific Pod (if you have a suspect)

echo ""
echo "If you want to examine errors from a specific pod (e.g., 'problematic-pod-123'), modify the query:"
echo ""
echo "SELECT"
echo "    json_payload.kubernetes.pod_name,"
echo "    json_payload.message,"
echo "    timestamp"
echo "FROM"
echo "  \`$PROJECT_ID.global.\$BQ_DATASET_NAME.cloudaudit_googleapis_com_data_access\`"
echo "WHERE"
echo "  resource.labels.cluster_name = 'cepf-autopilot-cluster'"
echo "  AND json_payload.kubernetes.pod_name = 'problematic-pod-123'" # replace
echo "  AND json_payload.level = 'ERROR'"
echo "  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)"
echo "ORDER BY"
echo "  timestamp DESC"
echo ";"
echo ""
echo "Remember to replace 'problematic-pod-123' with the actual pod name."

# 3. Aggregating Errors by Pod

echo ""
echo "To get a summary of errors per pod in the last hour:"
echo ""
echo "SELECT"
echo "    json_payload.kubernetes.pod_name,"
echo "    COUNT(*) AS error_count"
echo "FROM"
echo "  \`$PROJECT_ID.global.\$BQ_DATASET_NAME.cloudaudit_googleapis_com_data_access\`"
echo "WHERE"
echo "  resource.labels.cluster_name = 'cepf-autopilot-cluster'"
echo "  AND json_payload.level = 'ERROR'"
echo "  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)"
echo "GROUP BY"
echo "    json_payload.kubernetes.pod_name"
echo "ORDER BY"
echo "    error_count DESC"
echo ";"
echo ""
echo "This query groups the logs by pod name and counts the number of error messages, allowing you to quickly identify the pods with the most errors."

# Advice for Troubleshooting

echo ""
echo "Once you identify error messages or problematic pods:"
echo "- Carefully examine the error messages for clues about the root cause."
echo "- Look for patterns or correlations in the logs. Are multiple pods experiencing the same issue?"
echo "- Consider checking application code, configurations, or external dependencies."
echo "- If the errors are related to resource limits, check the pod's resource requests and limits in the Kubernetes manifest."
echo "- For persistent errors, consider collecting more detailed logs (e.g., debug level) or using application-specific monitoring tools."
echo ""
echo "**Important Note:** Adapt these queries and filters based on the actual structure"
echo "of your application's logs and the error indicators it uses (e.g., log levels,"
echo "specific error messages, or other relevant fields)."
