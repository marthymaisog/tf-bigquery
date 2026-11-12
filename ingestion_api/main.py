from datetime import datetime
import json
import os
import uuid
from fastapi import FastAPI, HTTPException, status
from google.cloud import storage
from pydantic import BaseModel

app = FastAPI(title="Game Telemetry Ingestion API")

# Initialize Google Cloud Storage client
storage_client = storage.Client()
BUCKET_NAME = os.getenv("BUCKET_NAME", "mygame-raw-events-bucket")


class GameEvent(BaseModel):
  event_id: str
  player_id: str
  event_name: str
  event_timestamp: str
  country: str | None = "UNKNOWN"
  platform: str | None = "UNKNOWN"
  custom_data: dict | None = {}


@app.post("/v1/telemetry", status_code=status.HTTP_202_ACCEPTED)
async def ingest_telemetry(event: GameEvent):
  try:
    # Structure path to match your Airflow DAG expectation: raw/YYYY-MM-DD/
    current_date = datetime.utcnow().strftime("%Y-%m-%d")
    file_name = f"raw/{current_date}/{event.event_id}_{uuid.uuid4()}.json"

    # Serialize event data
    event_data = event.dict()

    # Upload securely to GCS
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(file_name)
    blob.upload_from_string(
        json.dumps(event_data), content_type="application/json"
    )

    return {"status": "success", "message": "Telemetry received"}
  except Exception as e:
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
    )


@app.get("/health")
async def health_check():
  return {"status": "healthy"}