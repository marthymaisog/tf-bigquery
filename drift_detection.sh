#!/bin/bash

# Drift Detection Script for tf-bigquery
# Run this in your local environment or via Cloud Composer to verify state integrity.

set -e # Exit on any error

echo "🔍 Starting Drift Detection..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"

# 1. Validate State Consistency
echo ""
echo "📋 Validating Terraform State..."
terraform state list > drift_check_state.txt

# 2. Check for Drift against Live Infrastructure
echo ""
echo "🔎 Checking for configuration drift..."
set +e
terraform plan -detailed-exitcode -no-color > drift_plan_output.txt
PLAN_EXIT=$?
set -e

if [ $PLAN_EXIT -eq 0 ]; then
    echo "✅ No drift detected. Infrastructure matches state."
elif [ $PLAN_EXIT -eq 2 ]; then
    echo "⚠️ WARNING: Drift detected! Review 'drift_plan_output.txt'."
else
    echo "❌ ERROR: Terraform plan failed."
    exit 1
fi

# 3. Validate IAM & Policy Drift
echo ""
echo "🛡️ Checking IAM Policies..."
EXPECTED_ROLES=("roles/bigquery.dataViewer" "roles/storage.objectViewer")
for role in "${EXPECTED_ROLES[@]}"; do
    if terraform show -no-color | grep -q "$role"; then
        echo "✅ Role '$role' is correctly managed."
    else
        echo "❌ WARNING: Expected role '$role' not found in state!"
    fi
done

# 4. Check Cloud Storage & BigQuery State
echo ""
echo "📊 Checking Data Pipeline Resources..."
terraform state list | grep -E "(bucket|dataset)" > pipeline_drift.txt

if [ -s pipeline_drift.txt ]; then
    echo "✅ Bucket and Dataset resources are managed."
else
    echo "❌ WARNING: No bucket/dataset resources found in state!"
fi

# 5. Generate Final Report
echo ""
echo "📝 Generating Drift Report..."
cat drift_check_state.txt > drift_report.txt
echo "---" >> drift_report.txt
cat pipeline_drift.txt >> drift_report.txt

echo ""
echo "✅ Drift detection complete. Report saved to 'drift_report.txt'."