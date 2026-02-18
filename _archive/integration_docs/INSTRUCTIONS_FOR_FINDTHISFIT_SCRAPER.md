# Instructions for Find This Fit Scraper Team

## Context

The Modaics ML models (color/category classifiers) are currently performing poorly because the training data has incorrect labels:

- **58.7% of images labeled "unknown" color** (should be blue, black, red, etc.)
- **32.5% of images labeled "other" category** (should be jacket, shirt, pants, etc.)
- **Brand classifier works perfectly (99.6%)** because brand logos are visible in images

**Root Cause**: The current scraper only captures unstructured `title` and `description` fields. When we export training data, we parse titles with keyword matching ("blue" in title → blue folder), but 58.7% of titles don't mention color, so images get mislabeled as "unknown".

**The Solution**: Extract **structured metadata from marketplace APIs** instead of relying on title parsing.

---

## Current Scraper (BROKEN)

Your current Find This Fit scraper captures:

```python
# Current fashion_items table
{
  "title": "Prada Candy Cosmetictoiletry Bags Boxed",  # Unstructured text
  "description": "Vintage bag from 2000s...",          # Unstructured text
  "brand": None,      # ❌ Not extracted
  "category": None,   # ❌ Not extracted
  "color": None,      # ❌ Not extracted (added later via title parsing)
  "image_url": "https://...",
  "price": 125.00
}
```

When we train ML models:
1. We parse title: "Does it contain 'blue'? No → unknown folder"
2. Image of actual blue bag → filed in `color_classifier/unknown/` 
3. Create ML learns: "This is what 'unknown' looks like" (visually)
4. Result: 92.7% confidence predicting "unknown" for blue items

---

## Required Changes

### 1. Extract Structured Data from Marketplace APIs

**Depop API Example**:
```python
# Depop API response (you're already getting this!)
{
  "id": 12345,
  "title": "Supreme Box Logo Hoodie",
  "description": "Rare 2016 release...",
  "price": 450.00,
  "brand_id": 235,           # ← USE THIS! Map to brand name
  "category_id": 12,         # ← USE THIS! Map to category name
  "colour": "Navy",          # ← USE THIS! Already structured!
  "colour_id": 8,
  "condition": "Used - Excellent",
  "size_id": 15,
  "size_attributes": {
    "size": "L"
  },
  "photos": [...]
}
```

**Grailed API Example**:
```python
# Grailed API response
{
  "id": 98765,
  "title": "AMI Paris Wool Jacket Navy Size 48",
  "price": "$280.00",
  "designer": {             # ← USE THIS!
    "id": 523,
    "name": "AMI Paris"
  },
  "category": {             # ← USE THIS!
    "id": 42,
    "path": ["Menswear", "Outerwear", "Jackets"]
  },
  "color": "Blue",          # ← USE THIS!
  "size": "48",
  "condition": "Gently Used",
  "photos": [...]
}
```

**Vinted API Example**:
```python
# Vinted API response
{
  "id": 4927925810,
  "title": "Banana Republic Khaki Straight Chinos Men 38X32",
  "price": "25.00",
  "brand_id": 1234,         # ← USE THIS! Map to brand name
  "brand_title": "Banana Republic",  # ← Already provided!
  "catalog_branch_id": 56,  # ← USE THIS! Map to category
  "color_id": 12,           # ← USE THIS!
  "color_title": "Beige",   # ← Already provided!
  "size_title": "38",
  "status": "good",
  "photos": [...]
}
```

### 2. Create Mapping Tables

You'll need to map API IDs to standardized names:

```python
# maps.py

# Depop brand_id → name mapping
DEPOP_BRANDS = {
    235: "Supreme",
    156: "Nike",
    189: "Adidas",
    523: "AMI Paris",
    # ... (scrape from Depop's brand list API)
}

# Depop category_id → standardized category
DEPOP_CATEGORIES = {
    12: "hoodie",
    15: "jacket",
    8: "jeans",
    23: "sneakers",
    # ... (scrape from Depop's category API)
}

# Grailed designer_id → name
GRAILED_BRANDS = {
    523: "AMI Paris",
    612: "Prada",
    # ... (from Grailed designers API)
}

# Vinted brand_id → name (they provide brand_title, use that!)
# Vinted catalog_branch_id → category
VINTED_CATEGORIES = {
    56: "pants",
    78: "jacket",
    # ...
}
```

### 3. Update Your Scraper Code

**Before (BROKEN)**:
```python
async def scrape_depop_item(item_data):
    """Old way - only captures unstructured data"""
    return {
        'source': 'depop',
        'external_id': item_data['id'],
        'title': item_data['title'],
        'description': item_data.get('description'),
        'price': item_data['price'],
        'image_url': item_data['photos'][0]['url'],
        'brand': None,      # ❌ Missing
        'category': None,   # ❌ Missing
        'condition': None   # ❌ Missing
    }
```

**After (CORRECT)**:
```python
from maps import DEPOP_BRANDS, DEPOP_CATEGORIES

async def scrape_depop_item(item_data):
    """New way - extract structured metadata"""
    
    # Map brand_id to name
    brand = DEPOP_BRANDS.get(item_data.get('brand_id'), 'Unknown')
    
    # Map category_id to standardized name
    category = DEPOP_CATEGORIES.get(item_data.get('category_id'), 'other')
    
    # Color is already provided as string!
    color = item_data.get('colour', 'unknown').lower()
    
    # Condition is structured
    condition = item_data.get('condition', 'Good')
    
    # Size from size_attributes
    size = item_data.get('size_attributes', {}).get('size', 'M')
    
    return {
        'source': 'depop',
        'external_id': item_data['id'],
        'title': item_data['title'],
        'description': item_data.get('description'),
        'price': item_data['price'],
        'image_url': item_data['photos'][0]['url'],
        'brand': brand,           # ✅ Structured!
        'category': category,     # ✅ Structured!
        'color': color,           # ✅ Structured!
        'condition': condition,   # ✅ Structured!
        'size': size              # ✅ Structured!
    }
```

### 4. Database Schema Update

Make sure your `fashion_items` table has these columns:

```sql
CREATE TABLE IF NOT EXISTS fashion_items (
    id SERIAL PRIMARY KEY,
    source VARCHAR(50),           -- 'depop', 'grailed', 'vinted'
    external_id VARCHAR(100),
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2),
    currency VARCHAR(10),
    url TEXT,
    image_url TEXT,
    seller_name VARCHAR(255),
    
    -- ✅ ADD THESE STRUCTURED FIELDS
    brand VARCHAR(100),           -- 'Supreme', 'Nike', 'AMI Paris', etc.
    category VARCHAR(50),         -- 'jacket', 'hoodie', 'jeans', 'sneakers', etc.
    color VARCHAR(50),            -- 'black', 'blue', 'navy', 'red', etc.
    condition VARCHAR(50),        -- 'New', 'Like New', 'Good', 'Fair', etc.
    size VARCHAR(20),             -- 'S', 'M', 'L', '32', '10', etc.
    
    embedding vector(512),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## Expected Results

### Before (Current):
```python
# Database data quality
{
  "total_items": 38970,
  "has_brand": 0,          # 0% have brand data
  "has_category": 0,       # 0% have category data
  "has_color": 0           # 0% have color data
}

# ML Training data (after title parsing)
{
  "unknown_colors": 22885,    # 58.7% mislabeled
  "other_categories": 12674,  # 32.5% mislabeled
}

# Model performance
{
  "color_accuracy": "92.7% predicting 'unknown'",  # ❌
  "category_accuracy": "41.8% (jacket → shirt)",   # ❌
  "brand_accuracy": "99.6%"                        # ✅ (logos visible)
}
```

### After (With Structured Data):
```python
# Database data quality
{
  "total_items": 100000,      # Larger scrape!
  "has_brand": 92000,         # 92% have brand data
  "has_category": 98000,      # 98% have category data
  "has_color": 89000          # 89% have color data
}

# ML Training data (no title parsing needed!)
{
  "unknown_colors": 11000,    # Only 11% truly unknown
  "other_categories": 2000,   # Only 2% truly other
}

# Expected model performance
{
  "color_accuracy": "85-90%",     # ✅ Navy jacket → "navy"
  "category_accuracy": "88-93%",  # ✅ Jacket → "jacket"
  "brand_accuracy": "99.6%"       # ✅ Still perfect
}
```

---

## Implementation Checklist

- [ ] **Get API documentation** for Depop, Grailed, Vinted structured fields
- [ ] **Create mapping tables** for brand_id → name, category_id → category
- [ ] **Update scraper code** to extract brand/category/color from API responses
- [ ] **Update database schema** to add brand/category/color/condition/size columns
- [ ] **Clear existing data**: `TRUNCATE TABLE fashion_items;` (avoid confusion with old data)
- [ ] **Run large scrape**: Target 100k+ items with structured metadata
- [ ] **Verify data quality**: Check that 90%+ items have brand/category/color populated
- [ ] **Export training data**: Use structured fields, not title parsing
- [ ] **Retrain ML models**: Should see 85-90% accuracy

---

## Sample Scraper Pseudocode

```python
import asyncio
import aiohttp
import asyncpg
from maps import DEPOP_BRANDS, DEPOP_CATEGORIES, GRAILED_BRANDS, VINTED_CATEGORIES

async def scrape_all_marketplaces():
    """Main scraping function"""
    
    # Connect to database
    conn = await asyncpg.connect(...)
    
    # Clear old data (avoid confusion)
    await conn.execute("TRUNCATE TABLE fashion_items CASCADE;")
    print("🗑️  Cleared old data")
    
    # Scrape each marketplace
    async with aiohttp.ClientSession() as session:
        depop_items = await scrape_depop(session, limit=50000)
        grailed_items = await scrape_grailed(session, limit=30000)
        vinted_items = await scrape_vinted(session, limit=20000)
    
    # Insert into database
    for item in depop_items + grailed_items + vinted_items:
        await conn.execute("""
            INSERT INTO fashion_items 
            (source, external_id, title, description, price, image_url, 
             brand, category, color, condition, size, url)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        """, 
            item['source'], item['external_id'], item['title'], 
            item['description'], item['price'], item['image_url'],
            item['brand'], item['category'], item['color'],
            item['condition'], item['size'], item['url']
        )
    
    print(f"✅ Scraped {len(depop_items + grailed_items + vinted_items):,} items")

async def scrape_depop(session, limit=50000):
    """Scrape Depop with structured metadata"""
    items = []
    
    for page in range(1, limit // 100):
        async with session.get(f'https://webapi.depop.com/api/v2/search/?limit=100&page={page}') as resp:
            data = await resp.json()
            
            for product in data['products']:
                items.append({
                    'source': 'depop',
                    'external_id': str(product['id']),
                    'title': product['title'],
                    'description': product.get('description', ''),
                    'price': product['price'],
                    'image_url': product['photos'][0]['url'],
                    'url': f"https://depop.com/products/{product['slug']}",
                    
                    # ✅ STRUCTURED DATA
                    'brand': DEPOP_BRANDS.get(product.get('brand_id'), 'Unknown'),
                    'category': DEPOP_CATEGORIES.get(product.get('category_id'), 'other'),
                    'color': product.get('colour', 'unknown').lower(),
                    'condition': product.get('condition', 'Good'),
                    'size': product.get('size_attributes', {}).get('size', 'M')
                })
    
    return items

# Similar for scrape_grailed() and scrape_vinted()
```

---

## Questions?

Contact the Modaics team if you need:
- API authentication help
- Brand/category mapping tables
- Database migration scripts
- Validation scripts to check data quality

**Goal**: 100k+ items with 90%+ having accurate brand/category/color metadata, leading to 85-90% ML model accuracy.
