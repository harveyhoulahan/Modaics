# How to Retrain ML Models with Better Data

## Problem Analysis

Your current models have poor accuracy because:

### Color Classifier
- **63% of training data is "unknown"** (9,289 / 14,629 images)
- Model learned that most items are "unknown" → defaults to it
- Only 393 blue examples, 270 navy, etc.

### Category Classifier  
- **28% is "other"** (4,121 / 14,629 images)
- Jacket (2,599) vs Shirt (885) confusion at boundaries
- Blue Supreme jacket → "shirt" at 41.8% confidence

### Brand Classifier
- **Actually works great!** Supreme at 99.6% ✅
- Good training data distribution

## Solution: Clean Training Data

### Step 1: Fix Colors in Database

Run this SQL to relabel "unknown" colors based on actual color names in titles:

```sql
-- Update items with color keywords in title
UPDATE items 
SET color = 'blue' 
WHERE (color IS NULL OR color = 'unknown') 
AND (title ILIKE '%blue%' OR title ILIKE '%navy%');

UPDATE items 
SET color = 'black'
WHERE (color IS NULL OR color = 'unknown')
AND title ILIKE '%black%';

UPDATE items
SET color = 'white'  
WHERE (color IS NULL OR color = 'unknown')
AND (title ILIKE '%white%' OR title ILIKE '%cream%');

UPDATE items
SET color = 'red'
WHERE (color IS NULL OR color = 'unknown')  
AND (title ILIKE '%red%' OR title ILIKE '%burgundy%');

UPDATE items
SET color = 'green'
WHERE (color IS NULL OR color = 'unknown')
AND (title ILIKE '%green%' OR title ILIKE '%olive%');

UPDATE items
SET color = 'brown'
WHERE (color IS NULL OR color = 'unknown')
AND (title ILIKE '%brown%' OR title ILIKE '%tan%' OR title ILIKE '%beige%');

UPDATE items  
SET color = 'gray'
WHERE (color IS NULL OR color = 'unknown')
AND (title ILIKE '%gray%' OR title ILIKE '%grey%' OR title ILIKE '%charcoal%');

UPDATE items
SET color = 'pink'  
WHERE (color IS NULL OR color = 'unknown')
AND title ILIKE '%pink%';

UPDATE items
SET color = 'purple'
WHERE (color IS NULL OR color = 'unknown')  
AND (title ILIKE '%purple%' OR title ILIKE '%lavender%');

UPDATE items
SET color = 'yellow'
WHERE (color IS NULL OR color = 'unknown')
AND (title ILIKE '%yellow%' OR title ILIKE '%mustard%');

UPDATE items
SET color = 'orange'  
WHERE (color IS NULL OR color = 'unknown')
AND (title ILIKE '%orange%' OR title ILIKE '%rust%');

-- Check remaining unknowns
SELECT COUNT(*) FROM items WHERE color = 'unknown' OR color IS NULL;
```

### Step 2: Fix Categories

```sql
-- Better category detection from titles
UPDATE items
SET category = 'jacket'
WHERE (category = 'other' OR category = 'shirt')  
AND (title ILIKE '%jacket%' OR title ILIKE '%coat%' OR title ILIKE '%blazer%');

UPDATE items
SET category = 'hoodie'
WHERE category = 'other'
AND (title ILIKE '%hoodie%' OR title ILIKE '%hoody%');

UPDATE items  
SET category = 'sweater'
WHERE category = 'other'
AND (title ILIKE '%sweater%' OR title ILIKE '%jumper%' OR title ILIKE '%cardigan%');

UPDATE items
SET category = 'jeans'  
WHERE category = 'pants'
AND title ILIKE '%jeans%';

UPDATE items
SET category = 'sneakers'
WHERE category = 'shoes'  
AND (title ILIKE '%sneaker%' OR title ILIKE '%trainer%');

-- Check remaining "other"
SELECT COUNT(*) FROM items WHERE category = 'other';
```

### Step 3: Re-Export Training Data

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
