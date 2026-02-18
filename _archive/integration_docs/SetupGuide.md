# Modaics - Complete Setup and Deployment Guide

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [iOS App Setup](#ios-app-setup)
4. [ML Model Training Setup](#ml-model-training-setup)
5. [Backend Infrastructure](#backend-infrastructure)
6. [Deployment](#deployment)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

## 🎯 Project Overview

Modaics is a sustainable fashion marketplace app that combines:
- **iOS App**: Native SwiftUI application with ML-powered recommendations
- **ML Pipeline**: Python-based training system for fashion embeddings
- **Core ML Integration**: On-device fashion similarity matching
- **Sustainability Tracking**: FibreTrace integration for verified sustainability

## 📦 Prerequisites

### For iOS Development
- macOS 12.0+ (Monterey or later)
- Xcode 14.0+
- iOS 16.0+ deployment target
- Apple Developer Account (for device testing)
- CocoaPods or Swift Package Manager

### For ML Training
- Python 3.8+
- CUDA-capable GPU (recommended)
- 16GB+ RAM
- 50GB+ free disk space

### Required Python Packages
```bash
pip install torch torchvision torchaudio
pip install coremltools
pip install scikit-learn
pip install pandas numpy
pip install pillow
pip install tqdm
pip install joblib
```

## 📱 iOS App Setup

### 1. Initial Project Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/modaics.git
cd modaics

# Navigate to iOS project
cd Modaics
```

### 2. Configure Xcode Project

1. Open `Modaics.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Update Bundle Identifier to match your team

### 3. Add Core ML Models

```bash
# Create Models directory
mkdir -p Modaics/Models

# Copy Core ML models (after training)
cp ../coreml_models/ResNet50Embedding.mlmodel Modaics/Models/
cp ../coreml_models/FashionEmbedding.mlmodel Modaics/Models/
```

### 4. Add Model Files to Xcode

1. In Xcode, right-click on the Modaics folder
2. Select "Add Files to Modaics..."
3. Navigate to Models folder and add:
   - `ResNet50Embedding.mlmodel`
   - `FashionEmbedding.mlmodel`
   - `Embeddings.json`
   - `Filenames.json`

### 5. Configure Info.plist

Add the following keys to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Modaics needs camera access to photograph fashion items for listing</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Modaics needs photo library access to select fashion item images</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Modaics uses your location to show nearby fashion swaps and events</string>
```

### 6. Configure App Capabilities

In Xcode, under Signing & Capabilities:
1. Add "Push Notifications" capability
2. Add "Background Modes" and enable:
   - Background fetch
   - Remote notifications

## 🤖 ML Model Training Setup

### 1. Prepare Dataset

```bash
# Create data directory structure
mkdir -p data/{train,val,test}
mkdir -p data/train/{tops,bottoms,dresses,outerwear,shoes,accessories}

# Download fashion dataset (example using Fashion Product Images dataset)
# Option 1: Kaggle Fashion Product Images Dataset
kaggle datasets download -d paramaggarwal/fashion-product-images-dataset

# Option 2: DeepFashion Dataset
# Visit http://mmlab.ie.cuhk.edu.hk/projects/DeepFashion.html
```

### 2. Organize Dataset

```python
# Run data preparation script
python scripts/prepare_dataset.py --input raw_data/ --output data/
```

### 3. Train the Model

```bash
# Run the complete training pipeline
python modaics_training_pipeline.py \
  --data-dir data \
  --output-dir models \
  --epochs 50 \
  --batch-size 64 \
  --lr 1e-4
```

### 4. Monitor Training

The training script will output:
- Training progress with loss and accuracy
- Validation metrics after each epoch
- Best model checkpoint saved to `models/best_fashion_model.pth`

### 5. Convert to Core ML

The pipeline automatically converts to Core ML, but you can also run manually:

```python
# Manual conversion if needed
python scripts/convert_to_coreml.py \
  --model-path models/best_fashion_model.pth \
  --output-dir coreml_models
```

## 🏗️ Backend Infrastructure

### 1. Firebase Setup (Recommended)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase project
firebase init

# Select:
# - Firestore
# - Storage
# - Functions
# - Authentication
```

### 2. Configure Firebase in iOS

1. Add `GoogleService-Info.plist` to Xcode project
2. Install Firebase SDK via Swift Package Manager:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Add required packages:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics

### 3. Database Schema

```javascript
// Firestore Collections

// users
{
  uid: "user123",
  username: "harvey",
  email: "user@example.com",
  profileImageURL: "https://...",
  bio: "Sustainable fashion enthusiast",
  location: "Melbourne, VIC",
  joinDate: Timestamp,
  isVerified: true,
  userType: "consumer", // or "brand"
  sustainabilityPoints: 250,
  following: ["user456", "user789"],
  followers: ["user234", "user567"],
  likedItems: ["item123", "item456"],
  wardrobe: ["item789", "item012"]
}

// items
{
  id: "item123",
  name: "Organic Cotton T-Shirt",
  brand: "Patagonia",
  category: "tops",
  size: "M",
  condition: "likeNew",
  originalPrice: 45.00,
  listingPrice: 25.00,
  description: "...",
  imageURLs: ["https://..."],
  sustainabilityScore: {
    totalScore: 85,
    carbonFootprint: 2.5,
    waterUsage: 1800,
    isRecycled: false,
    isCertified: true,
    certifications: ["GOTS", "Fair Trade"],
    fibreTraceVerified: true
  },
  materialComposition: [
    {name: "Organic Cotton", percentage: 100, isOrganic: true}
  ],
  colorTags: ["Navy", "Blue"],
  styleTags: ["Casual", "Basics"],
  location: "Melbourne, VIC",
  ownerId: "user123",
  createdAt: Timestamp,
  updatedAt: Timestamp,
  viewCount: 42,
  likeCount: 8,
  isAvailable: true
}

// transactions
{
  id: "trans123",
  itemId: "item123",
  sellerId: "user123",
  buyerId: "user456",
  type: "purchase", // or "swap", "rent"
  price: 25.00,
  status: "completed",
  createdAt: Timestamp,
  completedAt: Timestamp,
  trackingNumber: "TRACK123",
  review: {
    rating: 5,
    comment: "Great seller!",
    createdAt: Timestamp
  }
}
```

### 4. Cloud Functions

Create `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Trigger for new item listing
exports.onItemCreated = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snap, context) => {
    const item = snap.data();
    
    // Update user's sustainability score
    await updateUserSustainabilityScore(item.ownerId);
    
    // Send notification to followers
    await notifyFollowers(item.ownerId, item);
  });

// Calculate similarity recommendations
exports.getSimilarItems = functions.https.onCall(async (data, context) => {
  const { itemId, embedding } = data;
  
  // Query similar embeddings from Firestore
  // Return top 10 similar items
});
```

## 🚀 Deployment

### 1. iOS App Deployment

#### TestFlight Beta Testing
```bash
# Archive and upload to App Store Connect
# In Xcode: Product > Archive
# Then upload to App Store Connect

# Configure TestFlight
# 1. Add internal testers
# 2. Submit for external testing
# 3. Monitor crash reports and feedback
```

#### App Store Release
1. Prepare marketing materials:
   - App icon (1024x1024)
   - Screenshots for all device sizes
   - App preview video (optional)
   - App description and keywords

2. Submit for review:
   - Complete App Information
   - Set pricing and availability
   - Submit for App Review

### 2. Backend Deployment

#### Firebase Deployment
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy hosting (if applicable)
firebase deploy --only hosting
```

## 🧪 Testing

### 1. Unit Tests

Create `ModaicsTests/FashionViewModelTests.swift`:

```swift
import XCTest
@testable import Modaics

class FashionViewModelTests: XCTestCase {
    var viewModel: FashionViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = FashionViewModel()
    }
    
    func testFilteringByCategory() {
        // Given
        viewModel.allItems = FashionItem.sampleItems
        
        // When
        viewModel.selectedCategory = .tops
        viewModel.filterItems()
        
        // Then
        XCTAssertTrue(viewModel.filteredItems.allSatisfy { $0.category == .tops })
    }
    
    func testSustainabilityScoreCalculation() {
        // Test sustainability calculations
    }
}
```

### 2. UI Tests

Create `ModaicsUITests/ModaicsUITests.swift`:

```swift
import XCTest

class ModaicsUITests: XCTestCase {
    func testLoginFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for splash screen
        sleep(3)
        
        // Test login flow
        app.buttons["Get Started"].tap()
        app.buttons["Personal User"].tap()
        app.buttons["Continue"].tap()
        
        // Verify main app loads
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
```

### 3. ML Model Testing

```python
# test_model.py
import unittest
import torch
from modaics_training_pipeline import FashionFeatureExtractor

class TestFashionModel(unittest.TestCase):
    def setUp(self):
        self.model = FashionFeatureExtractor()
        self.model.eval()
    
    def test_embedding_dimension(self):
        # Test that embeddings have correct dimension
        dummy_input = torch.randn(1, 3, 224, 224)
        embedding = self.model(dummy_input, return_embeddings=True)
        self.assertEqual(embedding.shape[1], 512)
    
    def test_similarity_scores(self):
        # Test similarity calculations
        pass

if __name__ == '__main__':
    unittest.main()
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Core ML Model Not Loading
```swift
// Check model is properly added to bundle
guard let modelURL = Bundle.main.url(forResource: "ResNet50Embedding", withExtension: "mlmodelc") else {
    print("Model not found in bundle")
    return
}
```

#### 2. Memory Issues During Training
```python
# Reduce batch size
python modaics_training_pipeline.py --batch-size 16

# Enable gradient checkpointing
model.backbone.requires_grad_(False)  # Freeze backbone initially
```

#### 3. Firebase Authentication Issues
```swift
// Ensure Firebase is configured
FirebaseApp.configure()

// Check authentication state
Auth.auth().addStateDidChangeListener { auth, user in
    if let user = user {
        print("User signed in: \(user.uid)")
    }
}
```

### Performance Optimization

#### 1. Image Caching
```swift
// Implement image caching
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}
```

#### 2. Lazy Loading
```swift
// Use lazy loading for heavy views
LazyVStack {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
```

#### 3. Background Processing
```swift
// Process embeddings in background
DispatchQueue.global(qos: .userInitiated).async {
    let embedding = self.computeEmbedding(for: image)
    DispatchQueue.main.async {
        self.updateUI(with: embedding)
    }
}
```

## 📚 Additional Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [PyTorch Documentation](https://pytorch.org/docs/stable/index.html)
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)

### Tutorials
- [Core ML Tutorial](https://developer.apple.com/tutorials/app-dev-training/creating-a-core-ml-model)
- [Fashion MNIST with PyTorch](https://pytorch.org/tutorials/beginner/blitz/cifar10_tutorial.html)

### Community
- [Modaics GitHub Discussions](https://github.com/yourusername/modaics/discussions)
- [Stack Overflow - modaics tag](https://stackoverflow.com/questions/tagged/modaics)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.