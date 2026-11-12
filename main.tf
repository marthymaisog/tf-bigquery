terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Use local backend for testing to avoid credential cycles
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.airflow_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.airflow_cluster.master_auth[0].cluster_ca_certificate)
}

# Terraform state bucket (referenced in output.tf)
resource "google_storage_bucket" "tf_state" {
  project                     = var.project_id
  name                        = "${var.cloud_storage_bucket_prefix}${var.environment}-tf-state-${var.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
}

output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}