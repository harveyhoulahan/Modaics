# How to Retrain ML Models with Better Data

## Problem Analysis

Your current models have poor accuracy NOT because of bad labeling, but because **58.7% of your source data lacks color information in titles** and **32.5% can't be categorized from title alone**.

### Current Training Data (from title parsing):
- **Color**: 58.7% "unknown" (22,885 / 38,970 items) - titles don't mention color
- **Category**: 32.5% "other" (12,674 / 38,970 items) - can't determine from title
- **Brand**: 61.4% "other" (23,941 / 38,970 items) - not in top 35 tracked brands

### Model Performance:
- **Brand Classifier**: 99.6% ✅ (works because visible in images - Supreme logo)
- **Color Classifier**: 92.7% predicting "unknown" ❌ (learned that most items are "unknown")
- **Category Classifier**: 41.8% predicting "shirt" for jacket ❌ (confusion between similar categories)

## Root Cause: Unstructured Source Data

Your Find This Fit scraper only captures:
```python
# fashion_items table
title: "Prada Candy Cosmetictoiletry Bags Boxed"  # Unstructured
description: None
brand: None  # Not extracted
category: None  # Not extracted
color: None  # Not extracted
```

You then parse titles with keyword matching:
```python
# export_createml_data.py
if 'blue' in title_lower: color = 'blue'
if 'jacket' in title_lower: category = 'jacket'
if 'prada' in title_lower: brand = 'prada'
# → 58.7% don't mention color, 32.5% don't fit categories
```

## Solution 1: Use Marketplace APIs (BEST)

## Solution 1: Use Marketplace APIs (BEST)

Depop, Grailed, and Vinted all provide structured data in their APIs:

**Depop API** (example):
```json
{
  "id": "12345",
  "title": "Supreme Box Logo Hoodie",
  "price": 450,
  "brand_id": 235,  // ← Structured brand!
  "category_id": 12,  // ← Structured category!
  "colour": "Navy",  // ← Structured color!
  "condition": "Used - Excellent",
  "size": "L",
  "description": "...",
  "photos": ["url1", "url2"]
}
```

**Update your scrapers** to extract these fields:
```python
# In your Depop scraper
async def scrape_depop_item(item_id):
    data = await fetch_depop_api(item_id)
    
    return {
        'title': data['title'],
        'brand': BRAND_MAP.get(data['brand_id'], 'Unknown'),  # Map ID to name
        'category': CATEGORY_MAP.get(data['category_id']),
        'color': data['colour'],  # Already structured!
        'condition': data['condition'],
        'size': data['size'],
        # ...
    }
```

**Expected improvement:**
- Colors: 58.7% "unknown" → **~10% unknown** (only items truly missing data)
- Categories: 32.5% "other" → **~5% other** (only truly uncategorizable items)

## Solution 2: Vision API for Color (MEDIUM)

Use your existing Vision color detection to label the 22,885 "unknown" items:

```python
# populate_colors_from_vision.py
import asyncio
import asyncpg
from ModaicsAppTemp.IOS.Shared.VisionAnalysisService import VisionAnalysisService

async def populate_missing_colors():
    conn = await asyncpg.connect(...)
    vision = VisionAnalysisService()
    
    # Get items with unknown color
    items = await conn.fetch("""
        SELECT id, image_url 
        FROM fashion_items 
        WHERE color = 'unknown' AND image_url IS NOT NULL
    """)
    
    for item in items:
        image = download_image(item['image_url'])
        colors = await vision.detectColors(in: image)
        
        if colors:
            await conn.execute("""
                UPDATE fashion_items 
                SET color = $1 
                WHERE id = $2
            """, colors[0], item['id'])
```

**Expected improvement:**
- Colors: 58.7% "unknown" → **~15% unknown** (some images still unclear)

## Solution 3: Manual Category Rules (QUICK FIX)

```bash
# Delete old training images
rm -rf createml_training_data/color_classifier/*
rm -rf createml_training_data/category_classifier/*

# Re-export with cleaned data
python3 export_createml_data.py
```

### Step 4: Retrain in Create ML

**Color Classifier:**
1. Open Create ML
2. New Image Classifier
3. Training Data: `createml_training_data/color_classifier/`
4. Iterations: 25
5. Augmentations: Crop, Rotate, Blur, Expose
6. Validation: 20%
7. Train (30-40 min)
8. **Target Accuracy: 80-90%** (currently getting "unknown" 93%)

**Category Classifier:**
1. Same process with `category_classifier/`
2. **Target Accuracy: 85-95%** (currently 41.8% on jacket)

### Step 5: Replace Models

```bash
# Copy new models
cp ~/Desktop/FashionColourClassifier.mlmodel ModaicsAppTemp/ModaicsAppTemp/ML\ Models/
cp ~/Desktop/FashionCategoryClassifier.mlmodel ModaicsAppTemp/ModaicsAppTemp/ML\ Models/

# Clean Xcode derived data to force recompile
rm -rf ~/Library/Developer/Xcode/DerivedData/ModaicsAppTemp-*
```

## Expected Results After Retraining

### Before (Current):
```
🎨 ML Color: unknown (92.7%)
🏷️ ML Category: shirt (41.8%)
👔 ML Brand: supreme (99.6%) ✅
```

### After (Target):
```
🎨 ML Color: blue (87.3%) ✅
🏷️ ML Category: jacket (89.2%) ✅  
👔 ML Brand: supreme (99.6%) ✅
```

## Quick Check: Training Data Quality

Run this to see current distribution:

```bash
# Color distribution
cd createml_training_data/color_classifier
for dir in */; do 
    count=$(find "$dir" -type f -name "*.jpg" | wc -l)
    echo "$count - $(basename "$dir")"
done | sort -rn

# Category distribution  
cd ../category_classifier
for dir in */; do
    count=$(find "$dir" -type f -name "*.jpg" | wc -l)
    echo "$count - $(basename "$dir")"  
done | sort -rn
```

**Good training data has:**
- No class > 30% of total
- Each class has 200+ examples
- Similar distribution across classes
- NO "unknown" or "other" > 10%
