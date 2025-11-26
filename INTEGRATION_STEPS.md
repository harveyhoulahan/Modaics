# FindThisFit → Modaics Integration Guide

**Date:** November 25, 2025  
**Goal:** Integrate FindThisFit's CLIP search engine into Modaics as the "Discover" tab

---

## ✅ What's Been Prepared in Modaics

The following has been set up automatically:

1. **Backend structure** at `backend/` (ready to receive FindThisFit files)
2. **Database schema** at `database/init.sql` (fashion_items + user_wardrobe + more)
3. **Docker setup** in `docker-compose.yml` (PostgreSQL + pgvector)
4. **Dependencies** in `requirements.txt` (sentence-transformers, pgvector, FastAPI)
5. **Swift API client** at `ModaicsAppTemp/ModaicsAppTemp/IOS/Shared/SearchAPIClient.swift`

---

## 🚨 CRITICAL: Wait for FindThisFit Embedding to Complete

**Before proceeding, check if FindThisFit's embedding is finished:**

```bash
# In FindThisFit directory
docker exec -i findthisfit-db psql -U postgres -d find_this_fit -c \
  "SELECT COUNT(*) as total, COUNT(embedding) as embedded FROM fashion_items;"
```

**Expected output when complete:**
```
 total | embedded
-------+----------
 25677 | 25677
```

If `embedded` < `total`, wait for the embedding process to finish (currently at 74%, ~6,649 items remaining).

---

## 📋 Step-by-Step Integration

### Step 1: Copy FindThisFit Backend Files

```bash
# Navigate to Modaics backend directory
cd /Users/harveyhoulahan/Desktop/Modaics/Modaics/backend

# Copy core FindThisFit backend files
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/app.py ./
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/embeddings.py ./
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/search.py ./
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/models.py ./

# Copy any additional utilities
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/backend/*.py ./
```

### Step 2: Update Backend Configuration

Edit `backend/app.py` to use Modaics database:

```python
# Change database URL
DATABASE_URL = "postgresql://postgres:postgres@modaics-db:5432/modaics"

# OR for local development (outside Docker)
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/modaics"
```

### Step 3: Start Modaics Database

```bash
# From Modaics root directory
cd /Users/harveyhoulahan/Desktop/Modaics/Modaics

# Start database only (first time)
docker-compose up -d modaics-db

# Wait for database to be ready
docker-compose logs -f modaics-db
# Wait for "database system is ready to accept connections"
```

### Step 4: Migrate FindThisFit Data

**Option A: Export/Import SQL Dump (Recommended)**

```bash
# 1. Export FindThisFit data
docker exec -i findthisfit-db pg_dump -U postgres -d find_this_fit \
  --table=fashion_items --data-only \
  > /tmp/findthisfit_data.sql

# 2. Import into Modaics database
docker exec -i modaics-db psql -U postgres -d modaics < /tmp/findthisfit_data.sql

# 3. Verify import
docker exec -i modaics-db psql -U postgres -d modaics -c \
  "SELECT COUNT(*) FROM fashion_items;"
# Should show: 25677
```

**Option B: Direct Database Copy (Faster)**

```bash
# Dump and restore in one command
docker exec -i findthisfit-db pg_dump -U postgres -d find_this_fit \
  --table=fashion_items --data-only | \
  docker exec -i modaics-db psql -U postgres -d modaics
```

### Step 5: Install Python Dependencies

```bash
# From Modaics root
cd /Users/harveyhoulahan/Desktop/Modaics/Modaics

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 6: Download CLIP Model

The CLIP model will auto-download on first run, but you can pre-download:

```python
# Run this Python script to cache the model
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('sentence-transformers/clip-ViT-B-32')
print("CLIP model downloaded successfully!")
```

### Step 7: Start Modaics Backend

```bash
# From Modaics root (with venv activated)
cd /Users/harveyhoulahan/Desktop/Modaics/Modaics

# Start backend server
python3 -m uvicorn backend.app:app --reload --host 0.0.0.0 --port 8000
```

**Expected output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Step 8: Test Backend Endpoints

Open new terminal:

```bash
# Health check
curl http://localhost:8000/health

# Test text search
curl -X POST http://localhost:8000/search_by_text \
  -H "Content-Type: application/json" \
  -d '{"query": "vintage Prada bag", "limit": 5}'

# Test combined search
curl -X POST http://localhost:8000/search_combined \
  -H "Content-Type: application/json" \
  -d '{"query": "Rick Owens sneakers", "limit": 5}'
```

**Expected response:**
```json
{
  "results": [
    {
      "id": 123,
      "title": "Vintage Prada Nylon Bag",
      "price": 450.00,
      "image_url": "https://...",
      "platform": "depop",
      "similarity": 0.95
    },
    ...
  ],
  "count": 5,
  "query_type": "text"
}
```

### Step 9: Update iOS App Configuration

Edit `ModaicsAppTemp/ModaicsAppTemp/IOS/App/ContentView.swift` (or wherever SearchAPIClient is initialized):

```swift
// Initialize search client with local backend
@StateObject private var searchClient = SearchAPIClient(baseURL: "http://localhost:8000")

// For iOS Simulator testing, use:
// @StateObject private var searchClient = SearchAPIClient(baseURL: "http://127.0.0.1:8000")
```

### Step 10: Integrate Search into DiscoverView

Update `EnhancedDiscoverView.swift` to use SearchAPIClient:

```swift
import SwiftUI

struct EnhancedDiscoverView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @StateObject private var searchClient = SearchAPIClient()
    
    @State private var searchText = ""
    @State private var selectedImage: UIImage?
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack {
            // Search bar
            SearchBar(text: $searchText)
            
            // Camera button for image search
            Button("Search by Photo") {
                // Show camera/photo picker
            }
            
            // Results
            if isSearching {
                ProgressView("Searching...")
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(searchResults) { result in
                            SearchResultCard(result: result)
                        }
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            Task {
                await performSearch(query: newValue)
            }
        }
    }
    
    func performSearch(query: String) async {
        guard !query.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            searchResults = try await searchClient.searchByText(query: query)
        } catch {
            print("Search error: \(error)")
        }
    }
}
```

### Step 11: Build and Run iOS App

```bash
# Open Xcode project
open /Users/harveyhoulahan/Desktop/Modaics/Modaics/ModaicsAppTemp/ModaicsAppTemp.xcodeproj

# In Xcode:
# 1. Select iOS Simulator (iPhone 15 Pro)
# 2. Product > Build (Cmd+B)
# 3. Product > Run (Cmd+R)
```

**Test the integration:**
1. Navigate to Discover tab
2. Type "vintage Prada"
3. Should see results from FindThisFit's 25,677 items

---

## 🔧 Troubleshooting

### Backend won't start
```bash
# Check if port 8000 is in use
lsof -i :8000

# Kill existing process
kill -9 <PID>

# Check database connection
docker exec -i modaics-db psql -U postgres -d modaics -c "SELECT 1;"
```

### Database connection error
```bash
# Restart database
docker-compose restart modaics-db

# Check logs
docker-compose logs modaics-db
```

### CLIP model download fails
```bash
# Manual download
python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/clip-ViT-B-32')"
```

### iOS can't connect to backend
```swift
// For iOS Simulator, use localhost or 127.0.0.1
let searchClient = SearchAPIClient(baseURL: "http://127.0.0.1:8000")

// For physical device, use your Mac's IP address
let searchClient = SearchAPIClient(baseURL: "http://192.168.1.XXX:8000")
```

To find your Mac's IP:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

---

## 📊 Verify Integration Success

### Backend Checklist
- [ ] `curl http://localhost:8000/health` returns 200
- [ ] Database has 25,677 items
- [ ] Text search returns results
- [ ] Image search works (test with base64 image)
- [ ] No errors in backend logs

### iOS Checklist
- [ ] App builds without errors
- [ ] SearchAPIClient initialized correctly
- [ ] Discover tab sends API requests
- [ ] Results display in UI
- [ ] Images load from external URLs
- [ ] Clicking item opens detail view

### Database Checklist
```sql
-- Run these queries to verify data

-- 1. Check total items
SELECT COUNT(*) FROM fashion_items;
-- Expected: 25677

-- 2. Check embeddings exist
SELECT COUNT(*) FROM fashion_items WHERE embedding IS NOT NULL;
-- Expected: 25677

-- 3. Check platforms distribution
SELECT platform, COUNT(*) FROM fashion_items GROUP BY platform;
-- Should show depop, grailed, vinted

-- 4. Check price range
SELECT MIN(price), AVG(price), MAX(price) FROM fashion_items;

-- 5. Test vector search
SELECT title, price, platform 
FROM fashion_items 
ORDER BY embedding <=> (SELECT embedding FROM fashion_items LIMIT 1)
LIMIT 5;
-- Should return similar items
```

---

## 🚀 Next Steps After Integration

### 1. Add Image Upload to DiscoverView

Copy FindThisFit's camera functionality:

```bash
# Copy CameraView from FindThisFit
cp /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/miniapp/FindThisFit/CameraView.swift \
   /Users/harveyhoulahan/Desktop/Modaics/Modaics/ModaicsAppTemp/ModaicsAppTemp/IOS/Views/Item/
```

### 2. Implement Digital Wardrobe

Use the same CLIP search for user's personal items:

```swift
// In ProfileView or new WardrobeView
@StateObject private var searchClient = SearchAPIClient()

func searchMyWardrobe(query: String) async {
    // Backend will filter by user_id
    let results = try await searchClient.searchCombined(query: query, image: nil)
}
```

### 3. Add Sustainability Scoring

Update database with sustainability metadata:

```sql
-- Add sustainability scores to existing items
UPDATE fashion_items 
SET sustainability_score = 70,  -- Default for secondhand
    is_verified_sustainable = TRUE
WHERE platform IN ('depop', 'grailed', 'vinted');

-- Flag known sustainable brands
UPDATE fashion_items
SET sustainability_score = 90,
    is_verified_sustainable = TRUE
WHERE LOWER(brand) IN ('patagonia', 'reformation', 'everlane', 'stella mccartney');
```

### 4. Implement Filters

Extend search endpoints with Modaics filters:

```python
# backend/app.py
@app.post("/search_combined")
async def search_combined(
    query: Optional[str] = None,
    image_base64: Optional[str] = None,
    max_price: Optional[float] = None,  # NEW
    platform: Optional[str] = None,      # NEW
    sustainability_min: Optional[int] = None  # NEW
):
    results = await perform_clip_search(query, image_base64)
    
    # Apply filters
    if max_price:
        results = [r for r in results if r.price <= max_price]
    if platform:
        results = [r for r in results if r.platform == platform]
    if sustainability_min:
        results = [r for r in results if r.sustainability_score >= sustainability_min]
    
    return results
```

### 5. Keep Data Fresh

Set up automated scraping (optional):

```bash
# Copy scraper scripts
cp -r /Users/harveyhoulahan/Desktop/MiniApp/find-this-fit/ingestion \
      /Users/harveyhoulahan/Desktop/Modaics/Modaics/

# Run weekly via cron
# Add to crontab: 0 0 * * 0 cd /path/to/modaics && bash ingestion/auto_scrape_and_embed.sh
```

---

## 📁 File Structure After Integration

```
Modaics/
├── backend/                    # ✅ NEW: FindThisFit backend
│   ├── __init__.py
│   ├── app.py                 # Search endpoints
│   ├── embeddings.py          # CLIP model
│   ├── search.py              # pgvector queries
│   └── models.py              # SQLAlchemy models
├── database/                   # ✅ NEW
│   └── init.sql               # Schema with fashion_items
├── docker-compose.yml          # ✅ UPDATED: Added PostgreSQL
├── requirements.txt            # ✅ UPDATED: Added CLIP dependencies
├── ModaicsAppTemp/
│   └── ModaicsAppTemp/
│       └── IOS/
│           ├── Shared/
│           │   └── SearchAPIClient.swift  # ✅ NEW: API client
│           └── Views/
│               └── Item/
│                   └── EnhancedDiscoverView.swift  # UPDATE: Use SearchAPIClient
└── INTEGRATION_STEPS.md       # ✅ This file
```

---

## 🎯 Success Criteria

**Integration is complete when:**

1. ✅ Backend starts without errors
2. ✅ Database contains 25,677 fashion items with embeddings
3. ✅ Text search returns relevant results
4. ✅ Image search works from iOS app
5. ✅ Combined search uses both modalities
6. ✅ Results display correctly in Discover tab
7. ✅ External links (Depop/Grailed/Vinted) open in Safari

**Performance benchmarks:**
- Search latency: <200ms for text, <500ms for image
- UI response: Results appear within 1 second
- Database query: <100ms for vector similarity

---

## 💡 Tips

1. **Start backend before iOS app** - Backend must be running for searches to work
2. **Use Simulator for testing** - Easier to debug network requests
3. **Check backend logs** - `uvicorn` shows all API requests
4. **Monitor database** - Use TablePlus or pgAdmin to inspect data
5. **Cache CLIP model** - First run downloads ~500MB model

---

## 📞 Need Help?

**Check these first:**
1. Backend logs: `python3 -m uvicorn backend.app:app --reload` (terminal output)
2. Database logs: `docker-compose logs modaics-db`
3. iOS console: Xcode > View > Debug Area > Show Debug Area
4. Network requests: Xcode > Debug > Network Link Conditioner

**Common issues:**
- "Connection refused" → Backend not running
- "404 Not Found" → Wrong endpoint URL
- "Empty results" → Database not populated
- "CLIP model error" → Run model download script first

---

**END OF INTEGRATION GUIDE**

*Good luck! You're merging 25,677 AI-searchable fashion items into Modaics! 🚀*
