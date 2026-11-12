# 🎮 Game Analytics Infrastructure & Data Pipeline

A complete, production-grade end-to-end Data Platform for Game Analytics. This repository provisions the cloud infrastructure, deploys a real-time serverless ingestion API, orchestrates scheduled data cleaning pipelines, and feeds analytical datasets into BigQuery for visual reporting in Looker Studio.

---

## 🏗️ Architecture Overview

```text
               +-----------------------+
               |  Game Clients         |
               |  (Unity / Unreal)     |
               +-----------+-----------+
                           |
                           | HTTPS POST (JSON Telemetry)
                           v
               +-----------------------+
               | Ingestion API         |
               | (FastAPI on Cloud Run)|
               +-----------+-----------+
                           |
                           | Writes raw JSON batches
                           v
               +-----------------------+
               | Cloud Storage (GCS)   |
               |  gs://raw/YYYY-MM-DD/ |
               +-----------+-----------+
                           |
                           | Triggered daily / scheduled
                           v
               +-----------------------+
               | Airflow Orchestrator  |
               | (Composer / GKE)      |
               +-----------+-----------+
                           |
                           | Extracts, cleans, and loads
                           v
               +-----------------------+
               | BigQuery Warehouse    |
               | (game_events_clean)   |
               +-----------+-----------+
                           |
                           | Queries & Dashboards
                           v
               +-----------------------+
               | BI Dashboard          |
               | (Looker Studio)       |
               +-----------------------+
```

---

## 🛠️ Tech Stack

* **Infrastructure as Code (IaC):** Terraform (v1.4.0)
* **Cloud Platform:** Google Cloud Platform (GCP)
* **Ingestion Layer:** Serverless FastAPI application deployed on **Google Cloud Run**
* **Data Lake:** **Google Cloud Storage (GCS)** partitioned by date (`raw/YYYY-MM-DD/`)
* **Data Warehouse:** **Google BigQuery** (Partitioned & Clustered tables)
* **Orchestration:** **Apache Airflow** running on Google Kubernetes Engine (**GKE / Cloud Composer**)
* **Data Transformation:** SQL / PySpark / dbt compatible
* **Business Intelligence:** **Looker Studio** for live interactive dashboards
* **Continuous Integration & Deployment (CI/CD):** **GitHub Actions** with automated Terraform validation, plan review, and drift detection

---

## 📁 Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml             # GitHub Actions automation pipeline
├── terraform/
│   ├── provider.tf               # GCP Provider configuration
│   ├── cloud_storage.tf          # GCS raw telemetry bucket provisioning
│   ├── bigquery.tf               # BigQuery dataset & table definitions
│   ├── composer.tf               # GKE Cluster & Airflow deployment
│   ├── iam.tf                    # IAM roles & service account permissions
│   └── networking.tf             # VPC, subnets, & firewall rules
├── ingestion_api/
│   ├── main.py                   # FastAPI application receiving game events
│   ├── requirements.txt          # Python dependencies
│   └── Dockerfile                # Containerization specification
├── dags/
│   └── game_events_pipeline.py   # Airflow DAG for GCS to BigQuery ETL
└── README.md                     # Project documentation
```

---

## 🚀 System Components & Workflow

### 1. Infrastructure as Code (`/terraform`)
Terraform manages the full cloud environment declaratively.
* **Storage:** Provisions `mygame-raw-events-bucket` to hold raw JSON payloads from game sessions.
* **Compute:** Configures a GKE cluster running Apache Airflow for data workflow orchestration.
* **Data Warehouse:** Pre-creates the `game_analytics` BigQuery dataset and target analytical tables.

### 2. Ingestion Microservice (`/ingestion_api`)
A serverless REST API built with **FastAPI** running on **Google Cloud Run**.
* Game engines (Unity/Unreal) push event logs over HTTPS to `/v1/telemetry`.
* Validates schema attributes (`player_id`, `event_name`, `event_timestamp`, etc.).
* Generates unique identifiers and streams data into GCS bucket paths (`raw/YYYY-MM-DD/`).

### 3. Workflow Orchestration (`/dags`)
An Apache Airflow DAG (`game_events_pipeline.py`) runs on GKE to process raw logs.
* **Extraction:** Reads unprocessed daily files from Cloud Storage.
* **Transformation & Loading:** Cleans timestamp formatting, handles null values, deduplicates records, and loads clean records into BigQuery target tables.

### 4. Continuous Integration & Deployment (`.github/workflows`)
Automated pipelines ensure code quality and prevent unauthorized drift.
* **Trigger:** Direct pushes or Pull Requests targeting the `main` branch.
* **Terraform Validation:** Verifies syntax correctness and state synchronization against remote Google Cloud Storage backends.
* **Plan & Review:** Generates execution plan output (`plan.out`) using GCP service account credentials.
* **Drift Detection:** Identifies manual modifications made directly in the Google Cloud Console to ensure strict IaC compliance.

### 5. BI Dashboards & Visualization (Looker Studio)
Connects directly to BigQuery `game_events_transformed` tables for real-time reporting:
* **Key Metrics:** Daily Active Users (DAU), Player Retention, Session Duration, and In-Game Item Purchases.
* **Interactivity:** Time-range selectors, event filters, and region breakdowns for game designers and live-ops managers.

---

## ⚡ Deployment & Getting Started

### Prerequisites
* [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install) installed and authenticated.
* [Terraform v1.4.0+](https://developer.hashicorp.com/terraform/downloads) installed locally.
* A GCP Project with billing enabled.

---

### Step 1: Provision Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform with remote backend
terraform init \
  -backend-config="bucket=tf-bigquery-state-bucket" \
  -backend-config="prefix=tf_bigquery_state" \
  -backend-config="region=us-central1"

# Validate configuration
terraform validate

# Review plan
terraform plan

# Apply infrastructure changes
terraform apply -auto-approve
```

---

### Step 2: Deploy the Ingestion Microservice to Cloud Run

```bash
cd ../ingestion_api

# Deploy container directly from source to Cloud Run
gcloud run deploy game-ingestion-api \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars BUCKET_NAME=mygame-raw-events-bucket
```
*Note: Copy the service URL output by `gcloud` (e.g., `https://game-ingestion-api-xyz-uc.a.run.app/v1/telemetry`) to configure your game clients.*

---

### Step 3: Deploy Airflow DAGs

Deploy the DAG python file into your Airflow DAGs folder (or GCS DAGs bucket managed by Composer):

```bash
gsutil cp ../dags/game_events_pipeline.py gs://<YOUR_COMPOSER_DAGS_BUCKET>/dags/
```

---

### Step 4: Connect Looker Studio

1. Open [Looker Studio](https://lookerstudio.google.com).
2. Create a **New Blank Report**.
3. Select the **BigQuery** connector.
4. Choose your GCP Project -> `game_analytics` Dataset -> `game_events_transformed` Table.
5. Click **Add to Report** to start building charts and visual KPI scorecards.

---

## 🔒 Security Best Practices

* **No Hardcoded Credentials:** Game clients only interact with the public Cloud Run endpoint; direct GCS bucket access keys are never exposed.
* **IAM Least Privilege:** Dedicated GCP Service Accounts are used for Cloud Run writes and Airflow/BigQuery read-write execution.
* **Automated Auditing:** GitHub Actions runs drift detection checks to keep live cloud infrastructure 100% aligned with git commits.