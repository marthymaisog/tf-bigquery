FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Cloud Run automatically provides the PORT environment variable
ENV PORT=8080

CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT}