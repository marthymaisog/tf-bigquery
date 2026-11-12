# BigQuery Dataset (Game Analytics)
resource "google_bigquery_dataset" "game_analytics" {
  project    = var.project_id
  dataset_id = var.bigquery_dataset_id
  location   = var.region

  # Enable default partitioning expiration for cost optimization (in milliseconds: 30 days)
  default_partition_expiration_ms = 2592000000

  labels = {
    environment = var.environment
    team        = "data-engineering"
  }
}

# Raw Game Events Table (Partitioned by date)
resource "google_bigquery_table" "game_events_raw" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.game_analytics.dataset_id
  table_id   = "${var.environment}_raw_game_events"

  schema = jsonencode([
    { name = "user_id", type = "STRING", mode = "NULLABLE" },
    { name = "session_id", type = "STRING", mode = "NULLABLE" },
    { name = "event_type", type = "STRING", mode = "NULLABLE" },
    { name = "timestamp", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "game_version", type = "STRING", mode = "NULLABLE" }
  ])

  # Partition by timestamp field to improve query performance
  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  # Clustering for faster lookups
  clustering = ["user_id"]
}

# Transformed/Validated Table Schema
resource "google_bigquery_table" "game_events_transformed" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.game_analytics.dataset_id
  table_id   = "${var.environment}_game_events_processed"

  schema = jsonencode([
    { name = "user_id", type = "STRING", mode = "NULLABLE" },
    { name = "session_id", type = "STRING", mode = "NULLABLE" },
    { name = "event_type", type = "STRING", mode = "NULLABLE" },
    { name = "processed_at", type = "TIMESTAMP", mode = "NULLABLE" }
  ])
}