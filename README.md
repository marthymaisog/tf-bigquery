# 🎮 Secure & Scalable Game Telemetry Pipeline on GCP

An end-to-end, cloud-native game telemetry data platform built on Google Cloud Platform (GCP). This project implements modern data engineering best practices, featuring Infrastructure as Code (IaC), a serverless edge ingestion layer protected by Google Cloud Armor, automated Airflow orchestration, and native BI visualization.

## 🏗️ Architecture & Data Flow

```text
               +-----------------------+
               |  Game Clients         |
               |  (Unity / Unreal)     |
               +-----------+-----------+
                           |
                           | HTTPS POST (JSON Telemetry)
                           v
               +-----------------------+
               | Cloud Armor + HTTPS LB|
               | (Rate Limit / DDoS)   |
               +-----------+-----------+
                           |
                           | Internal Load Balancer Traffic
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

1. **Edge Security & Load Balancing:** Game clients send HTTPS POST requests to a public endpoint. Traffic passes through a **Google Cloud External HTTP(S) Load Balancer** protected by **Cloud Armor** (enforcing IP-based rate limiting and mitigating DDoS/flooding attacks).
2. **Serverless Ingestion API:** A stateless Python microservice built with **FastAPI** and **Pydantic** running on **Google Cloud Run** (restricted to internal load balancer ingress) validates incoming event schemas in real time.
3. **Data Lake Storage:** Validated events are written as date-partitioned JSON files (`raw/YYYY-MM-DD/`) into an immutable **Google Cloud Storage (GCS)** bucket.
4. **Orchestration & Transformation:** **Apache Airflow** running on a **GKE** cluster executes scheduled DAGs to load raw files into **BigQuery** and execute SQL/dbt transformations.
5. **Business Intelligence:** **Looker Studio** connects natively to BigQuery to serve live visual dashboards (DAU, retention, custom game metrics) to stakeholders.

## 🛠️ Tech Stack

* **Infrastructure as Code (IaC):** Terraform (>= 1.5.0)
* **Cloud Platform:** Google Cloud Platform (GCP)
* **Edge Security & Networking:** Google Cloud Armor, External HTTP(S) Load Balancer, Serverless NEG
* **Ingestion Layer:** Serverless FastAPI + Pydantic deployed on **Google Cloud Run**
* **Data Lake:** **Google Cloud Storage (GCS)** partitioned by date (`raw/YYYY-MM-DD/`)
* **Data Warehouse:** **Google BigQuery** (Partitioned & Clustered tables)
* **Orchestration:** **Apache Airflow** running on Google Kubernetes Engine (**GKE / Cloud Composer**)
* **Data Transformation:** SQL / PySpark / dbt compatible
* **Business Intelligence:** **Looker Studio** for live interactive dashboards
* **Continuous Integration & Deployment (CI/CD):** **GitHub Actions** with automated Terraform validation, plan review, and drift detection

## 📁 Repository Structure

```text
my-game-analytics-repo/
├── .github/
│   └── workflows/
│       └── ci-cd.yml             # GitHub Actions automation pipeline
├── terraform/                    # Infrastructure as Code (Terraform)
│   ├── main.tf                   # Provider configurations & backend setup
│   ├── variables.tf              # Global input variables
│   ├── outputs.tf                # Resource outputs (bucket names, service URLs)
│   ├── cloud_storage.tf          # GCS raw data lake bucket provisioning
│   ├── bigquery.tf               # BigQuery datasets and staging tables
│   ├── gke.tf / composer.tf      # Kubernetes cluster & Airflow environment
│   ├── cloud_armor.tf            # DDoS & IP rate-limiting security policies
│   ├── load_balancer.tf          # HTTPS Load Balancer & Serverless NEG wiring
│   ├── iam.tf                    # IAM roles & service account permissions
│   └── networking.tf             # VPC, subnets, & firewall rules
├── ingestion_api/                # Serverless Ingestion Microservice
│   ├── main.py                   # FastAPI application & Pydantic schema validation
│   ├── requirements.txt          # Python dependency manifest
│   └── Dockerfile                # Container definition for Cloud Run
├── dags/                         # Apache Airflow Pipeline Definitions
│   └── game_events_pipeline.py   # DAG moving GCS data into BigQuery
└── README.md                     # Project documentation
```

## ⚡ Getting Started & Deployment

### Prerequisites

* [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install) installed and authenticated (`gcloud auth login`).
* [Terraform (>= 1.5.0)](https://developer.hashicorp.com/terraform/downloads) installed locally.
* Docker installed for container builds.
* A GCP Project with billing enabled.

### Step 1: Provision Infrastructure with Terraform

Navigate to your Terraform directory, validate your configuration (including Cloud Armor and Load Balancer rules), and apply:

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review and apply infrastructure changes
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 2: Build & Deploy the Ingestion API to Cloud Run

Build the container image and deploy the serverless API (configured to accept traffic via the Load Balancer):

```bash
cd ../ingestion_api

# Build and push container image
gcloud builds submit --tag gcr.io/<YOUR_PROJECT_ID>/game-ingestion-api:latest

# Deploy to Cloud Run
gcloud run deploy game-ingestion-api \
  --image gcr.io/<YOUR_PROJECT_ID>/game-ingestion-api:latest \
  --region us-central1 \
  --ingress internal-and-cloud-load-balancing \
  --set-env-vars BUCKET_NAME=mygame-raw-events-bucket
```

### Step 3: Deploy Airflow DAGs

Upload the DAG definition to your Composer/Airflow DAGs bucket:

```bash
gsutil cp ../dags/game_events_pipeline.py gs://<YOUR_COMPOSER_DAGS_BUCKET>/dags/
```

### Step 4: Connect Looker Studio for BI Dashboards

1. Open [Looker Studio](https://lookerstudio.google.com).
2. Create a new **Report** and select the **BigQuery** connector.
3. Select your GCP Project, `game_analytics` Dataset, and transformed game metrics table.
4. Add scorecard widgets, time-series charts, and date range filters to build your live game telemetry dashboard.

## 🔒 Security Best Practices

* **Edge DDoS & Flood Protection:** Cloud Armor sits in front of the External Load Balancer, automatically throttling or blocking abusive IP addresses (`HTTP 429`) before requests reach compute containers.
* **Network Isolation:** Cloud Run ingress is restricted to `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`, preventing malicious actors from bypassing Cloud Armor via the direct `.run.app` URL.
* **No Hardcoded Credentials:** Game clients only interact with the public Load Balancer endpoint; direct GCS bucket access keys are never embedded in game builds.
* **IAM Least Privilege:** Dedicated GCP Service Accounts govern Cloud Run writes and Airflow/BigQuery execution.