output "service_account_email" {
  description = "Email address of the Airflow service account"
  value       = google_service_account.airflow_sa.email
}

output "storage_bucket_name" {
  description = "Name of the raw game events storage bucket"
  value       = google_storage_bucket.game_events.name
}

output "bigquery_dataset_id" {
  description = "ID of the BigQuery dataset"
  value       = google_bigquery_dataset.game_analytics.dataset_id
}

output "airflow_container_name" {
  description = "Name of the Airflow container in Cloud Composer"
  value       = google_container_cluster.airflow_cluster.name
}

output "terraform_state_bucket_url" {
  description = "URL to Terraform state bucket"
  value       = "gs://${google_storage_bucket.tf_state.name}"
}