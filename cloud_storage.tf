# Raw Game Events Storage Bucket
resource "google_storage_bucket" "game_events" {
  project                     = var.project_id
  name                        = lower("${var.cloud_storage_bucket_prefix}${var.environment}-raw-game-events-${var.project_id}")
  location                    = var.region
  uniform_bucket_level_access = true

  # Enable versioning for audit trail
  versioning {
    enabled = true
  }

  # Lifecycle rule: Delete old events after 90 days
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }
}

# Bucket IAM: Admins, Readers (for CI/CD), Airflow SA (read-only)
resource "google_storage_bucket_iam_member" "bucket_admins" {
  bucket = google_storage_bucket.game_events.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.project_id}@cloudbuild.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "bucket_readers" {
  bucket = google_storage_bucket.game_events.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.project_id}@cloudbuild.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "airflow_read_only" {
  bucket = google_storage_bucket.game_events.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.airflow_sa.email}"
}