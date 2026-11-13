# 1. Cloud Run Service restricted to accept traffic only from the Load Balancer
resource "google_cloud_run_v2_service" "ingestion_api" {
  name     = "game-ingestion-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" # Valid Cloud Run v2 ingress option

  template {
    containers {
      image = "gcr.io/${var.project_id}/game-ingestion-api:latest"
      env {
        name  = "BUCKET_NAME"
        value = "mygame-raw-events-bucket"
      }
    }
  }
}

# 2. Serverless NEG pointing to the Cloud Run service
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "game-api-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.ingestion_api.name
  }
}

# 3. Backend Service with the Cloud Armor Security Policy attached
resource "google_compute_backend_service" "default" {
  name                  = "game-api-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.game_security_policy.id

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}