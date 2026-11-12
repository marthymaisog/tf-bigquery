from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

# --- Configuration aligned with your Terraform setup ---
PROJECT_ID = "your-gcp-project-id"
BUCKET_NAME = "mygame-raw-events-bucket"  # Matches your cloud_storage.tf naming convention
DATASET_ID = "game_analytics"             # Matches bigquery.tf dataset
RAW_TABLE = "game_events_raw"             # Matches time-partitioned/clustered raw table
TRANSFORMED_TABLE = "game_events_transformed"  # Matches processed events table

default_args = {
    "owner": "game-data-team",
    "depends_on_past": False,
    "email_on_failure": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="game_events_daily_etl",
    default_args=default_args,
    description="ETL pipeline for raw game events stored via Terraform-provisioned GCS and BigQuery",
    schedule_interval="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["game-analytics", "terraform-managed"],
) as dag:

    # Step 1: Load raw JSON events from GCS into the partitioned BigQuery raw table
    load_raw_events = GCSToBigQueryOperator(
        task_id="load_gcs_to_bq_raw",
        bucket=BUCKET_NAME,
        source_objects=["raw/{{ ds }}/*.json"],
        destination_project_dataset_table=f"{PROJECT_ID}.{DATASET_ID}.{RAW_TABLE}",
        source_format="NEWLINE_DELIMITED_JSON",
        write_disposition="WRITE_APPEND",
        autodetect=False,  # Schema is pre-defined in bigquery.tf
    )

    # Step 2: Clean, deduplicate, and move data into the transformed table
    transform_events = BigQueryInsertJobOperator(
        task_id="transform_raw_to_clean",
        configuration={
            "query": {
                "query": f"""
                    INSERT INTO `{PROJECT_ID}.{DATASET_ID}.{TRANSFORMED_TABLE}`
                    (event_id, player_id, event_name, event_timestamp, country, platform)
                    SELECT DISTINCT
                        event_id,
                        player_id,
                        LOWER(TRIM(event_name)) AS event_name,
                        TIMESTAMP(event_timestamp) AS event_timestamp,
                        COALESCE(country, 'UNKNOWN') AS country,
                        platform
                    FROM `{PROJECT_ID}.{DATASET_ID}.{RAW_TABLE}`
                    WHERE DATE(event_timestamp) = '{{{{ ds }}}}'
                      AND player_id IS NOT NULL
                """,
                "useLegacySql": False,
            }
        },
    )

    # Task execution order
    load_raw_events >> transform_events
