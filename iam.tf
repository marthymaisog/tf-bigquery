# Airflow Service Account (Restricted Permissions)
resource "google_service_account" "airflow_sa" {
  project      = var.project_id
  account_id   = "${var.environment}-airflow-${var.service_account_name}"
  display_name = "Airflow Service Account (${var.environment})"
}

# BigQuery Dataset IAM (Read-only for Airflow)
resource "google_bigquery_dataset_iam_member" "airflow_read_only" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.game_analytics.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.airflow_sa.email}"
}

# Audit Logs for Service Account Access
resource "google_logging_project_bucket_config" "airflow_audit" {
  project   = var.project_id
  location  = "global"
  bucket_id = "${var.environment}-airflow-audit-logs-${var.project_id}"
}