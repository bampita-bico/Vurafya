FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# Apply migrations and start server
CMD ["sh", "-c", "python scripts/migrate.py --quiet && uvicorn backend.main:app --host 0.0.0.0 --port 8000"]

EXPOSE 8000
