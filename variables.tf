variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region (e.g., us-central1)"
  type        = string
}

variable "zone" {
  description = "GCP Zone (e.g., us-central1-a)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "service_account_name" {
  description = "Service account suffix"
  type        = string
}

variable "cloud_storage_bucket_prefix" {
  description = "Prefix for cloud storage bucket name"
  type        = string
}

variable "bigquery_dataset_id" {
  description = "BigQuery dataset ID for game analytics"
  type        = string
  default     = "game_analytics"
}