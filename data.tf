resource "google_service_account_key" "airflow_sa_key" {
  service_account_id = google_service_account.airflow_sa.name
}

data "google_storage_bucket" "game_events" {
  name = google_storage_bucket.game_events.name
}

data "google_bigquery_dataset" "game_analytics" {
  project    = google_bigquery_dataset.game_analytics.project
  dataset_id = google_bigquery_dataset.game_analytics.dataset_id
}