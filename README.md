# 🎮 Game Analytics Pipeline - Terraform Infrastructure

This repository contains the Infrastructure as Code (IaC) configuration for deploying a serverless and containerized game analytics data pipeline on Google Cloud Platform (GCP). 

The architecture provisions a secure data ingestion and processing environment utilizing **BigQuery**, **Cloud Storage**, **GKE (Apache Airflow)**, and custom **VPC Networking**.

---

## 🏗️ Architecture Components

* **BigQuery (`bigquery.tf`)**: Creates a game analytics dataset, a time-partitioned/clustered raw events table (`game_events_raw`), and a processed events table (`game_events_transformed`).
* **Cloud Storage (`cloud_storage.tf`)**: Provisions a raw event storage bucket with uniform bucket-level access, object versioning, and a 90-day deletion lifecycle rule.
* **Networking (`networking.tf`)**: Sets up a dedicated custom VPC (`main_vpc`), a private subnet (`airflow_subnet`) with private Google access, and ingress/egress firewall rules.
* **Compute / GKE (`composer.tf`)**: Provisions a Google Kubernetes Engine (GKE) cluster (`airflow_cluster`) and deploys Apache Airflow using a Kubernetes StatefulSet (`kubernetes_stateful_set_v1`).
* **IAM & Security (`iam.tf`)**: Establishes a least-privilege Airflow service account (`airflow_sa`), grants read-only BigQuery permissions, and sets up a project audit logging bucket (`airflow_audit`).
* **Drift Detection (`drift_detection.sh`)**: A utility script to verify state consistency, check resource deployment, and flag any configuration drift.

---

## 📂 Repository Structure

```text
.
├── bigquery.tf           # BigQuery dataset and table schemas
├── cloud_storage.tf      # GCS raw event bucket, lifecycle rules, and IAM bindings
├── composer.tf           # GKE cluster configuration and Airflow StatefulSet deployment
├── data.tf               # GCP data sources (buckets, datasets, service account keys)
├── drift_detection.sh    # Script to check infrastructure state and configuration drift
├── iam.tf                # Airflow service account, dataset IAM, and logging buckets
├── main.tf               # Terraform provider setup (Google & Kubernetes) and local backend
├── networking.tf         # VPC, private subnets, and firewall configurations
├── output.tf             # Terraform deployment output variables
└── variables.tf          # Global input variables (project ID, region, environment, etc.)
```

---

## 🚀 Getting Started

### Prerequisites
Make sure you have the following tools installed and configured:
* [Terraform](https://www.developer.hashicorp.com/terraform/downloads) (~> 5.0 provider compatibility)
* [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install)
* Authenticated GCP credentials (`gcloud auth application-default login`)

### 1. Configure Variables
Create a `terraform.tfvars` file in the root directory and supply your project-specific values:

```hcl
project_id                  = "your-gcp-project-id"
region                      = "us-central1"
zone                        = "us-central1-a"
environment                 = "dev"
service_account_name        = "sa"
cloud_storage_bucket_prefix = "mygame"
bigquery_dataset_id         = "game_analytics"
```

### 2. Initialize Terraform
Initialize the working directory to download required providers (Google and Kubernetes):
```bash
terraform init
```

### 3. Validate Configuration
Ensure your configuration is syntactically valid:
```bash
terraform validate
```

### 4. Preview Changes
Review the execution plan to see what resources will be created:
```bash
terraform plan
```

### 5. Apply Configuration
Deploy the infrastructure to GCP:
```bash
terraform apply
```

---

## 🔍 Drift Detection

To verify that your live cloud infrastructure matches your Terraform state without unexpected manual modifications, run the provided drift detection script:

```bash
chmod +x drift_detection.sh
./drift_detection.sh
```
The script will review current state bindings, execute a detailed infrastructure plan, check expected IAM roles, and save a summary report to `drift_report.txt`.

---

## 📊 Outputs
Once applied, Terraform will export helpful resource references:
* `service_account_email`: Email address of the Airflow service account.
* `storage_bucket_name`: Name of the raw game events GCS bucket.
* `bigquery_dataset_id`: ID of the BigQuery dataset.
* `airflow_container_name`: Name of the GKE cluster running Airflow.