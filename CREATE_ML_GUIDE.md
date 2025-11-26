# Create ML Training Guide for Modaics

## Overview
We'll train 3 Image Classifier models using Apple's Create ML app:
1. **Category Classifier** - 19 categories (jacket, bag, sweater, etc.)
2. **Color Classifier** - 14 colors (black, blue, brown, etc.)
3. **Brand Classifier** - 35+ brands (Gucci, Prada, Lee, etc.)

## Training Data
- **Total**: 35,040 images (6.9 GB)
- **Location**: `createml_training_data/`
- **Distribution**:
  - Category: 14,629 images (~770 per class)
  - Color: 14,629 images (~1,045 per class)
  - Brand: 5,782 images (~165 per brand)

## Step-by-Step Instructions

### 1. Open Create ML
```bash
# Open Create ML from Applications or Spotlight
# Or run from terminal:
open /Applications/Xcode.app/Contents/Applications/Create\ ML.app
```

### 2. Create Category Classifier

1. **New Project**
   - Click "New Document"
   - Choose "Image Classifier"
   - Name: `FashionCategoryClassifier`
   - Save location: `ModaicsAppTemp/ModaicsAppTemp/ML Models/`

2. **Set Training Data**
   - Click "Choose..." next to Training Data
   - Navigate to: `createml_training_data/category_classifier/`
   - Select the entire folder

3. **Configure Settings**
   - Algorithm: Automatic (or Transfer Learning)
   - Max Iterations: 25 (default is good)
   - Augmentation: ✅ Enable (for better accuracy)
   - Validation: Automatic (20% split)

4. **Train**
   - Click "Train" button
   - Wait 15-30 minutes (depends on your Mac)
   - Monitor accuracy in the Evaluation tab

5. **Export Model**
   - Once training completes, click "Get"
   - Save as: `FashionCategoryClassifier.mlmodel`
   - Location: `ModaicsAppTemp/ModaicsAppTemp/ML Models/`

### 3. Create Color Classifier

Repeat the same process:
1. New Project → Image Classifier
2. Name: `FashionColorClassifier`
3. Training Data: `createml_training_data/color_classifier/`
4. Train with same settings
5. Export as: `FashionColorClassifier.mlmodel`

### 4. Create Brand Classifier

Repeat again:
1. New Project → Image Classifier
2. Name: `FashionBrandClassifier`
3. Training Data: `createml_training_data/brand_classifier/`
4. Train with same settings
5. Export as: `FashionBrandClassifier.mlmodel`

## Expected Training Times
- **Category**: 20-40 minutes (19 classes, 14.6k images)
- **Color**: 20-40 minutes (14 classes, 14.6k images)
- **Brand**: 15-25 minutes (35 classes, 5.8k images)

**Total**: ~1-2 hours for all 3 models

## Expected Accuracy
Based on data quality:
- **Category**: 85-95% (very good data)
- **Color**: 80-90% (some "unknown" noise)
- **Brand**: 75-85% (fewer images per class)

## Tips for Best Results

### During Training:
- ✅ **Enable augmentation** - Helps with varied lighting/angles
- ✅ **Use automatic validation** - 20% holdout for testing
- ✅ **Monitor evaluation metrics** - Check precision/recall
- ❌ **Don't over-train** - 25 iterations is usually enough
- ❌ **Don't interrupt training** - Let it complete fully

### After Training:
- Check confusion matrix for problem classes
- Test with real photos from your phone
- Retrain if accuracy < 70% for any model

## Troubleshooting

### "Not enough data" error:
- Make sure each subfolder has at least 10 images
- Check that folder names don't have special characters

### Low accuracy:
- Enable augmentation
- Increase max iterations to 50
- Check for mislabeled images in folders

### Training very slow:
- Close other apps
- Plug in power (won't train on battery)
- Check Activity Monitor for CPU/Memory

## Next Steps

After exporting all 3 `.mlmodel` files:
1. Drag them into Xcode project
2. Add to ModaicsAppTemp target
3. Xcode will auto-generate Swift classes
4. Update VisionAnalysisService to use the models

---

**Ready to start?** Open Create ML and follow the steps above! 🚀
