# Cloud Composer Environment Cluster (GKE-based)
resource "google_container_cluster" "airflow_cluster" {
  project    = var.project_id
  name       = "${var.environment}-airflow-cluster-${var.project_id}"
  location   = var.region
  network    = google_compute_network.main_vpc.id
  subnetwork = google_compute_subnetwork.airflow_subnet.id

  initial_node_count = 1

  network_policy {
    enabled = false
  }

  node_config {
    machine_type = "n2-standard-4"
    disk_size_gb = 100
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }
}

# Apache Airflow Deployment on GKE (using Kubernetes StatefulSet v1)
resource "kubernetes_stateful_set_v1" "airflow" {
  metadata {
    name = "airflow-webserver"
    labels = {
      app         = "apache-airflow"
      environment = var.environment
    }
  }

  spec {
    service_name = "airflow-webserver"
    replicas     = 1

    selector {
      match_labels = {
        app = "apache-airflow"
      }
    }

    template {
      metadata {
        labels = {
          app = "apache-airflow"
        }
      }

      spec {
        container {
          name  = "airflow-webserver"
          image = "apache/airflow:2.7.3"

          resources {
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }

            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }
}