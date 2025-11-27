# Modaics Docker Connection Status ✅

**Last Updated:** November 26, 2025  
**Status:** All systems operational

## 🎯 Connection Summary

### ✅ Database (PostgreSQL + pgvector)
- **Container:** `modaics-db`
- **Image:** `pgvector/pgvector:pg16`
- **Status:** Running and healthy
- **Ports:** `5433:5432` (host:container)
- **Database:** `modaics`
- **Items:** 38,970 fashion items with CLIP embeddings
- **Extensions:** pgvector enabled for vector similarity search

### ✅ Backend API (FindThisFit)
- **Container:** `findthisfit-api`
- **Image:** `find-this-fit-backend`
- **Status:** Running and healthy
- **Ports:** `8000:8000` (host:container)
- **Framework:** FastAPI with uvicorn
- **Model:** sentence-transformers/clip-ViT-B-32
- **Database Connection:** ✅ Connected to modaics-db

### ✅ iOS App Configuration
- **SearchAPIClient baseURL:** `http://10.20.99.164:8000`
- **Local Network IP:** `10.20.99.164`
- **Status:** Configured correctly ✅

## 🔌 Available Endpoints

### Health & Monitoring
- `GET /health` - Health check endpoint
- `GET /metrics` - Database and performance metrics

### Search Endpoints
- `POST /search_by_image` - Upload image for visual search
- `POST /search_by_text` - Text-based fashion search
- `POST /search_combined` - Combined image + text search

### AI Analysis
- `POST /analyze_image` - AI-powered item analysis
  - Detects: brand, category, size, condition, colors, materials, price
  - Uses 38,970 items for smart predictions
- `POST /generate_description` - AI product description generation

## 🧪 Testing the Connection

Run the test script:
```bash
cd /Users/harveyhoulahan/Desktop/Modaics/Modaics
./test_connection.sh
```

Or manually test the API:
```bash
# Health check
curl http://localhost:8000/health

# From iOS device/simulator on same network
curl http://10.20.99.164:8000/health
```

## 🏗️ Database Schema

The database includes the following tables:
- `fashion_items` - 38,970 marketplace items with CLIP embeddings
- `user_wardrobe` - User-owned items (digital wardrobe)
- `users` - User accounts and profiles
- `transactions` - Sales, swaps, and rentals
- `events` - Community swap events and pop-ups
- `style_challenges` - Gamification challenges
- `analytics_events` - Usage tracking

All tables have vector similarity search enabled via pgvector.

## 🚀 Managing the Stack

### Start all services
```bash
docker-compose up -d
```

### Start specific service
```bash
docker-compose up -d backend-api
docker-compose up -d modaics-db
```

### Stop all services
```bash
docker-compose down
```

### View logs
```bash
docker-compose logs -f backend-api
docker-compose logs -f modaics-db
```

### Restart services
```bash
docker-compose restart backend-api
```

## 📊 Current Configuration

### docker-compose.yml Services
1. **modaics-db** - PostgreSQL with pgvector
2. **backend-api** - FastAPI CLIP search backend
3. **ml-training** - ML training service (profile: training)

### Environment Variables
```env
DATABASE_URL=postgresql://postgres:postgres@modaics-db:5432/modaics
MODEL_PATH=/app/models
CLIP_MODEL=sentence-transformers/clip-ViT-B-32
```

## 🔧 Troubleshooting

### If API fails to start
The API requires port 8000. If it's in use:
1. Check what's using it: `lsof -i :8000`
2. Stop the conflicting service, or
3. Update the port in `docker-compose.yml`

### If database is empty
Run the initialization script:
```bash
docker exec -i modaics-db psql -U postgres -d modaics < database/init.sql
```

### If iOS app can't connect
1. Verify both devices are on the same network
2. Check your local IP: `ipconfig getifaddr en0`
3. Update `SearchAPIClient` baseURL in `FashionViewModel.swift`
4. Ensure firewall allows connections to port 8000

## 📱 iOS Integration Points

### SearchAPIClient Methods
```swift
// Text search
searchClient.searchByText(query: "vintage denim jacket", limit: 20)

// Image search
searchClient.searchByImage(image: uploadedImage, limit: 20)

// Combined search
searchClient.searchCombined(query: "black hoodie", image: referenceImage, limit: 20)
```

### Converting Results to FashionItems
```swift
let items = searchResults.map { SearchAPIClient.toFashionItem($0) }
```

## 🎨 Features Available

### ✅ Implemented
- Vector similarity search with CLIP embeddings
- Text-based search
- Image-based search
- Combined multimodal search
- AI item analysis (brand, category, size, condition, price)
- Health monitoring
- Database connection pooling
- CORS for iOS app

### 🚧 Future Enhancements
- User authentication
- Wardrobe management API
- Transaction processing
- Event creation and RSVP
- Social features (follows, likes)
- Style challenges

## 📝 Notes

- The `findthisfit-api` container is the same as `modaics-api` (just different naming)
- Database has 38,970 items from Depop, Grailed, and Vinted
- All items have 768-dimensional CLIP embeddings for visual search
- HNSW index enabled for fast vector similarity search (~10-50ms)
- Database runs on port 5433 to avoid conflicts with other PostgreSQL instances

---

**Status:** ✅ All connections verified and operational  
**Last Test:** November 26, 2025  
**Quick Test:** `./test_connection.sh`
