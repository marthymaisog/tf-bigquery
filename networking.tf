# VPC for Cloud Composer/Airflow
resource "google_compute_network" "main_vpc" {
  name                    = "${var.environment}-vpc-${var.project_id}"
  project                 = var.project_id
  auto_create_subnetworks = false
}

# Subnet for Airflow Cluster (Private)
resource "google_compute_subnetwork" "airflow_subnet" {
  name                     = "${var.environment}-airflow-subnet-${var.project_id}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main_vpc.id
  ip_cidr_range            = "10.128.0.0/24"
  private_ip_google_access = true
}

# Firewall Rule: Allow Airflow web/API ingress
resource "google_compute_firewall" "airflow_ingress" {
  name      = "${var.environment}-airflow-ingress-${var.project_id}"
  project   = var.project_id
  network   = google_compute_network.main_vpc.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443", "8080"]
  }

  source_ranges = ["10.128.0.0/24"]
}

# Firewall Rule: Deny direct SSH
resource "google_compute_firewall" "airflow_deny_ssh" {
  name      = "${var.environment}-airflow-deny-ssh-${var.project_id}"
  project   = var.project_id
  network   = google_compute_network.main_vpc.id
  direction = "INGRESS"
  priority  = 1000

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}