# Modaics Backend

## Setup Instructions

### 1. Copy FindThisFit Backend Files

From your FindThisFit directory, copy these files to this backend/ folder:

```bash
# Navigate to this directory
cd /Users/harveyhoulahan/Desktop/Modaics/Modaics/backend

# Copy FindThisFit backend files
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/app.py ./app.py
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/embeddings.py ./embeddings.py
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/search.py ./search.py
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/models.py ./models.py

# Copy any other utility files from FindThisFit backend
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/*.py ./
```

### 2. Start Backend Server

```bash
# From Modaics root directory
python3 -m uvicorn backend.app:app --reload --port 8000
```

### 3. Test Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Test search
curl -X POST http://localhost:8000/search_by_text \
  -H "Content-Type: application/json" \
  -d '{"query": "vintage Prada bag"}'
```

## API Endpoints (from FindThisFit)

- `POST /search_by_image` - Image-based search
- `POST /search_by_text` - Text-based search  
- `POST /search_combined` - Combined image + text search
- `GET /health` - Health check

## Database

Uses PostgreSQL with pgvector extension. See docker-compose.yml for setup.

Database contains 25,677 fashion items from Depop, Grailed, and Vinted with CLIP embeddings.
