🎮 Game Analytics Pipeline - Terraform InfrastructureThis repository contains the Infrastructure as Code (IaC) configuration for deploying a serverless and containerized game analytics data pipeline on Google Cloud Platform (GCP).The architecture provisions a secure data ingestion and processing environment utilizing BigQuery, Cloud Storage, GKE (Apache Airflow), and custom VPC Networking.   🏗️ Architecture ComponentsBigQuery (bigquery.tf): Creates a game analytics dataset, a time-partitioned/clustered raw events table (game_events_raw), and a processed events table (game_events_transformed).   Cloud Storage (cloud_storage.tf): Provisions a raw event storage bucket with uniform bucket-level access, object versioning, and a 90-day deletion lifecycle rule.   Networking (networking.tf): Sets up a dedicated custom VPC (main_vpc), a private subnet (airflow_subnet) with private Google access, and ingress/egress firewall rules.   Compute / GKE (composer.tf): Provisions a Google Kubernetes Engine (GKE) cluster (airflow_cluster) and deploys Apache Airflow using a Kubernetes StatefulSet (kubernetes_stateful_set_v1).   IAM & Security (iam.tf): Establishes a least-privilege Airflow service account (airflow_sa), grants read-only BigQuery permissions, and sets up a project audit logging bucket (airflow_audit).   Drift Detection (drift_detection.sh): A utility script to verify state consistency, check resource deployment, and flag any configuration drift.   📂 Repository StructurePlaintext.
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
🚀 Getting StartedPrerequisitesMake sure you have the following tools installed and configured:Terraform (~> 5.0 provider compatibility)Google Cloud CLI (gcloud)Authenticated GCP credentials (gcloud auth application-default login)1. Configure VariablesCreate a terraform.tfvars file in the root directory and supply your project-specific values:Terraformproject_id                  = "your-gcp-project-id"
region                      = "us-central1"
zone                        = "us-central1-a"
environment                 = "dev"
service_account_name        = "sa"
cloud_storage_bucket_prefix = "mygame"
bigquery_dataset_id         = "game_analytics"
2. Initialize TerraformInitialize the working directory to download required providers (Google and Kubernetes):Bashterraform init
3. Validate ConfigurationEnsure your configuration is syntactically valid:Bashterraform validate
4. Preview ChangesReview the execution plan to see what resources will be created:Bashterraform plan
5. Apply ConfigurationDeploy the infrastructure to GCP:Bashterraform apply
🔍 Drift DetectionTo verify that your live cloud infrastructure matches your Terraform state without unexpected manual modifications, run the provided drift detection script:   Bashchmod +x drift_detection.sh
./drift_detection.sh
The script will review current state bindings, execute a detailed infrastructure plan, check expected IAM roles, and save a summary report to drift_report.txt.   📊 OutputsOnce applied, Terraform will export helpful resource references:   service_account_email: Email address of the Airflow service account.   storage_bucket_name: Name of the raw game events GCS bucket.   bigquery_dataset_id: ID of the BigQuery dataset.   airflow_container_name: Name of the GKE cluster running Airflow.   
