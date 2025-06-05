#!/usr/bin/env python3
"""
Complete Model Training Pipeline for Modaics Fashion App
This script handles dataset preparation, model training, embedding extraction,
and Core ML conversion for the fashion recommendation system.
"""

import os
import json
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import torchvision.models as models
import torchvision.transforms as transforms
from torchvision.datasets import ImageFolder
import numpy as np
from PIL import Image
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.neighbors import NearestNeighbors
import joblib
import coremltools as ct
from tqdm import tqdm
import requests
from pathlib import Path
import argparse

# =====================================================
# 1. Dataset Preparation
# =====================================================

class FashionDatasetPreparator:
    """Prepare and organize fashion dataset for training"""
    
    def __init__(self, data_dir="data", output_dir="processed_data"):
        self.data_dir = Path(data_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def download_dataset(self):
        """Download fashion dataset (using DeepFashion or Fashion-MNIST as example)"""
        print("📥 Downloading fashion dataset...")
        
        # For production, replace with actual dataset download
        # Example: DeepFashion, Fashion Product Images Dataset, etc.
        
        # Create sample structure for demonstration
        categories = ['tops', 'bottoms', 'dresses', 'outerwear', 'shoes', 'accessories']
        
        for category in categories:
            category_dir = self.output_dir / 'train' / category
            category_dir.mkdir(parents=True, exist_ok=True)
            
            # In production, download actual images here
            print(f"   Created directory for {category}")
            
    def create_metadata(self):
        """Create metadata JSON for fashion items"""
        metadata = []
        
        # Walk through image directories and create metadata
        for category_dir in (self.output_dir / 'train').iterdir():
            if category_dir.is_dir():
                category = category_dir.name
                
                for img_path in category_dir.glob('*.jpg'):
                    item = {
                        'filename': img_path.name,
                        'category': category,
                        'brand': 'Sample Brand',  # In production, extract from dataset
                        'sustainability_score': np.random.randint(40, 95),
                        'materials': ['Cotton', 'Polyester'],  # Sample materials
                        'color': 'Blue',  # In production, use color detection
                        'style_tags': ['Casual', 'Modern'],  # Sample tags
                    }
                    metadata.append(item)
        
        # Save metadata
        with open(self.output_dir / 'metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"✅ Created metadata for {len(metadata)} items")
        
        return metadata

# =====================================================
# 2. Fashion Feature Extractor Model
# =====================================================

class FashionFeatureExtractor(nn.Module):
    """
    ResNet50-based feature extractor with additional fashion-specific layers
    """
    
    def __init__(self, num_categories=10, embedding_dim=512):
        super(FashionFeatureExtractor, self).__init__()
        
        # Load pretrained ResNet50
        self.backbone = models.resnet50(pretrained=True)
        
        # Remove the final classification layer
        self.feature_dim = self.backbone.fc.in_features
        self.backbone.fc = nn.Identity()
        
        # Add fashion-specific layers
        self.fashion_head = nn.Sequential(
            nn.Linear(self.feature_dim, 1024),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(1024, embedding_dim),
            nn.ReLU(),
        )
        
        # Category classifier
        self.category_classifier = nn.Linear(embedding_dim, num_categories)
        
        # Sustainability predictor
        self.sustainability_predictor = nn.Sequential(
            nn.Linear(embedding_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 1),
            nn.Sigmoid()  # Output 0-1 for sustainability score
        )
        
    def forward(self, x, return_embeddings=False):
        # Extract base features
        features = self.backbone(x)
        
        # Get fashion embeddings
        embeddings = self.fashion_head(features)
        
        if return_embeddings:
            return embeddings
        
        # Get predictions
        category_logits = self.category_classifier(embeddings)
        sustainability_score = self.sustainability_predictor(embeddings) * 100  # Scale to 0-100
        
        return {
            'embeddings': embeddings,
            'category_logits': category_logits,
            'sustainability_score': sustainability_score
        }

# =====================================================
# 3. Custom Fashion Dataset
# =====================================================

class FashionDataset(Dataset):
    """Custom dataset for fashion items with metadata"""
    
    def __init__(self, root_dir, metadata_file, transform=None):
        self.root_dir = Path(root_dir)
        self.transform = transform
        
        # Load metadata
        with open(metadata_file, 'r') as f:
            self.metadata = json.load(f)
        
        # Create label encoders
        self.category_encoder = LabelEncoder()
        categories = [item['category'] for item in self.metadata]
        self.category_encoder.fit(categories)
        
    def __len__(self):
        return len(self.metadata)
    
    def __getitem__(self, idx):
        item = self.metadata[idx]
        
        # Load image
        img_path = self.root_dir / 'train' / item['category'] / item['filename']
        image = Image.open(img_path).convert('RGB')
        
        if self.transform:
            image = self.transform(image)
        
        # Encode labels
        category_label = self.category_encoder.transform([item['category']])[0]
        sustainability_score = item['sustainability_score'] / 100.0  # Normalize to 0-1
        
        return {
            'image': image,
            'category': category_label,
            'sustainability': torch.tensor(sustainability_score, dtype=torch.float32),
            'filename': item['filename']
        }

# =====================================================
# 4. Training Pipeline
# =====================================================

class FashionModelTrainer:
    """Complete training pipeline for fashion model"""
    
    def __init__(self, data_dir, output_dir="models", device=None):
        self.data_dir = Path(data_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        self.device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"🖥️  Using device: {self.device}")
        
        # Data transforms
        self.train_transform = transforms.Compose([
            transforms.Resize(256),
            transforms.RandomCrop(224),
            transforms.RandomHorizontalFlip(),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
        self.val_transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
    def prepare_dataloaders(self, batch_size=32):
        """Prepare training and validation dataloaders"""
        
        # Load dataset
        dataset = FashionDataset(
            root_dir=self.data_dir,
            metadata_file=self.data_dir / 'metadata.json',
            transform=self.train_transform
        )
        
        # Split into train/val
        train_size = int(0.8 * len(dataset))
        val_size = len(dataset) - train_size
        train_dataset, val_dataset = torch.utils.data.random_split(
            dataset, [train_size, val_size]
        )
        
        # Update validation transform
        val_dataset.dataset.transform = self.val_transform
        
        # Create dataloaders
        train_loader = DataLoader(
            train_dataset, 
            batch_size=batch_size, 
            shuffle=True, 
            num_workers=4
        )
        
        val_loader = DataLoader(
            val_dataset, 
            batch_size=batch_size, 
            shuffle=False, 
            num_workers=4
        )
        
        return train_loader, val_loader, dataset.category_encoder
        
    def train_model(self, num_epochs=25, learning_rate=1e-4, batch_size=32):
        """Train the fashion feature extractor"""
        
        print("🏋️  Starting model training...")
        
        # Prepare data
        train_loader, val_loader, category_encoder = self.prepare_dataloaders(batch_size)
        num_categories = len(category_encoder.classes_)
        
        # Initialize model
        model = FashionFeatureExtractor(num_categories=num_categories).to(self.device)
        
        # Loss functions
        category_criterion = nn.CrossEntropyLoss()
        sustainability_criterion = nn.MSELoss()
        
        # Optimizer
        optimizer = optim.Adam([
            {'params': model.backbone.parameters(), 'lr': learning_rate * 0.1},  # Lower LR for pretrained
            {'params': model.fashion_head.parameters()},
            {'params': model.category_classifier.parameters()},
            {'params': model.sustainability_predictor.parameters()}
        ], lr=learning_rate)
        
        # Learning rate scheduler
        scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=10, gamma=0.1)
        
        # Training loop
        best_val_loss = float('inf')
        
        for epoch in range(num_epochs):
            # Training phase
            model.train()
            train_loss = 0.0
            train_correct = 0
            train_total = 0
            
            pbar = tqdm(train_loader, desc=f'Epoch {epoch+1}/{num_epochs} [Train]')
            for batch in pbar:
                images = batch['image'].to(self.device)
                categories = batch['category'].to(self.device)
                sustainability = batch['sustainability'].to(self.device)
                
                optimizer.zero_grad()
                
                # Forward pass
                outputs = model(images)
                
                # Calculate losses
                cat_loss = category_criterion(outputs['category_logits'], categories)
                sus_loss = sustainability_criterion(
                    outputs['sustainability_score'].squeeze(), 
                    sustainability * 100
                )
                
                # Combined loss with weights
                total_loss = cat_loss + 0.5 * sus_loss
                
                # Backward pass
                total_loss.backward()
                optimizer.step()
                
                # Statistics
                train_loss += total_loss.item()
                _, predicted = outputs['category_logits'].max(1)
                train_total += categories.size(0)
                train_correct += predicted.eq(categories).sum().item()
                
                pbar.set_postfix({
                    'loss': f"{total_loss.item():.4f}",
                    'acc': f"{100.*train_correct/train_total:.2f}%"
                })
            
            # Validation phase
            model.eval()
            val_loss = 0.0
            val_correct = 0
            val_total = 0
            
            with torch.no_grad():
                pbar = tqdm(val_loader, desc=f'Epoch {epoch+1}/{num_epochs} [Val]')
                for batch in pbar:
                    images = batch['image'].to(self.device)
                    categories = batch['category'].to(self.device)
                    sustainability = batch['sustainability'].to(self.device)
                    
                    outputs = model(images)
                    
                    cat_loss = category_criterion(outputs['category_logits'], categories)
                    sus_loss = sustainability_criterion(
                        outputs['sustainability_score'].squeeze(), 
                        sustainability * 100
                    )
                    total_loss = cat_loss + 0.5 * sus_loss
                    
                    val_loss += total_loss.item()
                    _, predicted = outputs['category_logits'].max(1)
                    val_total += categories.size(0)
                    val_correct += predicted.eq(categories).sum().item()
            
            avg_val_loss = val_loss / len(val_loader)
            val_accuracy = 100. * val_correct / val_total
            
            print(f"\n📊 Epoch {epoch+1} Summary:")
            print(f"   Train Loss: {train_loss/len(train_loader):.4f}")
            print(f"   Val Loss: {avg_val_loss:.4f}")
            print(f"   Val Accuracy: {val_accuracy:.2f}%")
            
            # Save best model
            if avg_val_loss < best_val_loss:
                best_val_loss = avg_val_loss
                torch.save({
                    'epoch': epoch,
                    'model_state_dict': model.state_dict(),
                    'optimizer_state_dict': optimizer.state_dict(),
                    'val_loss': avg_val_loss,
                    'val_accuracy': val_accuracy,
                    'category_encoder': category_encoder
                }, self.output_dir / 'best_fashion_model.pth')
                print(f"   ✅ Saved best model!")
            
            scheduler.step()
        
        print("\n🎉 Training completed!")
        return model, category_encoder

# =====================================================
# 5. Embedding Extraction
# =====================================================

class EmbeddingExtractor:
    """Extract and save embeddings for all fashion items"""
    
    def __init__(self, model_path, data_dir, device=None):
        self.device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.data_dir = Path(data_dir)
        
        # Load trained model
        checkpoint = torch.load(model_path, map_location=self.device)
        self.model = FashionFeatureExtractor(
            num_categories=len(checkpoint['category_encoder'].classes_)
        )
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model.to(self.device)
        self.model.eval()
        
        # Transform for inference
        self.transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
    def extract_all_embeddings(self, image_dir, output_file='embeddings.json'):
        """Extract embeddings for all images in directory"""
        
        print("🔍 Extracting embeddings...")
        
        embeddings = []
        filenames = []
        
        # Find all images
        image_paths = list(Path(image_dir).rglob('*.jpg')) + \
                     list(Path(image_dir).rglob('*.png'))
        
        for img_path in tqdm(image_paths, desc="Processing images"):
            try:
                # Load and transform image
                image = Image.open(img_path).convert('RGB')
                image_tensor = self.transform(image).unsqueeze(0).to(self.device)
                
                # Extract embedding
                with torch.no_grad():
                    embedding = self.model(image_tensor, return_embeddings=True)
                    embedding = embedding.cpu().numpy().squeeze()
                
                embeddings.append(embedding.tolist())
                filenames.append(str(img_path.name))
                
            except Exception as e:
                print(f"⚠️  Error processing {img_path}: {e}")
                continue
        
        # Save embeddings and filenames as JSON
        output_data = {
            'embeddings': embeddings,
            'filenames': filenames
        }
        
        output_path = self.data_dir / output_file
        with open(output_path, 'w') as f:
            json.dump(output_data, f)
        
        # Also save as separate files for iOS
        with open(self.data_dir / 'Embeddings.json', 'w') as f:
            json.dump(embeddings, f)
        
        with open(self.data_dir / 'Filenames.json', 'w') as f:
            json.dump(filenames, f)
        
        print(f"✅ Extracted {len(embeddings)} embeddings")
        
        return embeddings, filenames
    
    def build_similarity_index(self, embeddings):
        """Build nearest neighbor index for similarity search"""
        
        print("🔨 Building similarity index...")
        
        embeddings_array = np.array(embeddings)
        
        # Build cosine similarity index
        nn_index = NearestNeighbors(
            n_neighbors=10, 
            metric='cosine',
            algorithm='brute'  # For smaller datasets; use 'ball_tree' for larger
        )
        nn_index.fit(embeddings_array)
        
        # Save index
        joblib.dump(nn_index, self.data_dir / 'similarity_index.pkl')
        
        print("✅ Similarity index built and saved")
        
        return nn_index

# =====================================================
# 6. Core ML Conversion
# =====================================================

class CoreMLConverter:
    """Convert PyTorch model to Core ML format"""
    
    def __init__(self, model_path, output_dir="coreml_models"):
        self.model_path = Path(model_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def convert_to_coreml(self):
        """Convert trained model to Core ML format"""
        
        print("📱 Converting to Core ML...")
        
        # Load PyTorch model
        checkpoint = torch.load(self.model_path, map_location='cpu')
        model = FashionFeatureExtractor(
            num_categories=len(checkpoint['category_encoder'].classes_)
        )
        model.load_state_dict(checkpoint['model_state_dict'])
        model.eval()
        
        # Create a wrapper for embedding extraction only
        class EmbeddingModel(nn.Module):
            def __init__(self, base_model):
                super().__init__()
                self.backbone = base_model.backbone
                self.fashion_head = base_model.fashion_head
                
            def forward(self, x):
                features = self.backbone(x)
                embeddings = self.fashion_head(features)
                return embeddings
        
        embedding_model = EmbeddingModel(model)
        embedding_model.eval()
        
        # Trace the model
        example_input = torch.rand(1, 3, 224, 224)
        traced_model = torch.jit.trace(embedding_model, example_input)
        
        # Convert to Core ML
        mlmodel = ct.convert(
            traced_model,
            inputs=[ct.ImageType(
                name="input_image",
                shape=example_input.shape,
                scale=1/255.0,
                bias=[0, 0, 0],  # No bias for RGB
                color_layout='RGB'
            )],
            outputs=[ct.TensorType(name="output")]
        )
        
        # Add metadata
        mlmodel.author = "Modaics"
        mlmodel.short_description = "Fashion item feature extractor for sustainable fashion recommendations"
        mlmodel.input_description["input_image"] = "Fashion item image (224x224 RGB)"
        mlmodel.output_description["output"] = "512-dimensional fashion embedding vector"
        
        # Save Core ML model
        output_path = self.output_dir / "FashionEmbedding.mlmodel"
        mlmodel.save(output_path)
        
        print(f"✅ Core ML model saved to {output_path}")
        
        # Also save a ResNet50-only version for compatibility
        self.convert_resnet50_only()
        
        return mlmodel
    
    def convert_resnet50_only(self):
        """Convert just ResNet50 backbone for simpler integration"""
        
        print("📱 Converting ResNet50 backbone to Core ML...")
        
        # Load pretrained ResNet50
        resnet = models.resnet50(pretrained=True)
        resnet.fc = nn.Identity()  # Remove classifier
        resnet.eval()
        
        # Trace model
        example_input = torch.rand(1, 3, 224, 224)
        traced_model = torch.jit.trace(resnet, example_input)
        
        # Convert to Core ML
        mlmodel = ct.convert(
            traced_model,
            inputs=[ct.ImageType(
                name="input_image",
                shape=example_input.shape,
                scale=1/255.0,
                bias=[0, 0, 0]
            )],
            outputs=[ct.TensorType(name="output")]
        )
        
        # Add metadata
        mlmodel.short_description = "ResNet50 feature extractor (outputs 2048-d embedding)"
        mlmodel.input_description["input_image"] = "Input image of size 224x224"
        mlmodel.output_description["output"] = "2048-dimensional image embedding"
        
        # Save
        output_path = self.output_dir / "ResNet50Embedding.mlmodel"
        mlmodel.save(output_path)
        
        print(f"✅ ResNet50 Core ML model saved to {output_path}")

# =====================================================
# 7. Main Pipeline Orchestrator
# =====================================================

def main():
    """Run the complete training pipeline"""
    
    parser = argparse.ArgumentParser(description='Modaics Fashion Model Training Pipeline')
    parser.add_argument('--data-dir', type=str, default='data', help='Data directory')
    parser.add_argument('--output-dir', type=str, default='models', help='Output directory')
    parser.add_argument('--epochs', type=int, default=25, help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=32, help='Batch size')
    parser.add_argument('--lr', type=float, default=1e-4, help='Learning rate')
    parser.add_argument('--skip-training', action='store_true', help='Skip training, only convert model')
    
    args = parser.parse_args()
    
    print("🚀 Modaics Fashion Model Training Pipeline")
    print("=" * 50)
    
    # Step 1: Prepare dataset
    if not args.skip_training:
        print("\n📁 Step 1: Preparing dataset...")
        preparator = FashionDatasetPreparator(args.data_dir, "processed_data")
        preparator.download_dataset()
        metadata = preparator.create_metadata()
        
        # Step 2: Train model
        print("\n🏋️  Step 2: Training model...")
        trainer = FashionModelTrainer("processed_data", args.output_dir)
        model, category_encoder = trainer.train_model(
            num_epochs=args.epochs,
            learning_rate=args.lr,
            batch_size=args.batch_size
        )
    
    # Step 3: Extract embeddings
    print("\n🔍 Step 3: Extracting embeddings...")
    extractor = EmbeddingExtractor(
        Path(args.output_dir) / 'best_fashion_model.pth',
        "processed_data"
    )
    embeddings, filenames = extractor.extract_all_embeddings("processed_data/train")
    nn_index = extractor.build_similarity_index(embeddings)
    
    # Step 4: Convert to Core ML
    print("\n📱 Step 4: Converting to Core ML...")
    converter = CoreMLConverter(
        Path(args.output_dir) / 'best_fashion_model.pth',
        "coreml_models"
    )
    mlmodel = converter.convert_to_coreml()
    
    # Step 5: Create iOS integration files
    print("\n📄 Step 5: Creating iOS integration files...")
    
    # Copy necessary files to iOS project structure
    ios_models_dir = Path("Modaics/Models")
    ios_models_dir.mkdir(exist_ok=True)
    
    # Copy Core ML models
    import shutil
    shutil.copy("coreml_models/FashionEmbedding.mlmodel", ios_models_dir)
    shutil.copy("coreml_models/ResNet50Embedding.mlmodel", ios_models_dir)
    
    # Copy embeddings
    shutil.copy("processed_data/Embeddings.json", ios_models_dir)
    shutil.copy("processed_data/Filenames.json", ios_models_dir)
    
    print("\n✅ Pipeline completed successfully!")
    print(f"   - Trained model saved to: {args.output_dir}/best_fashion_model.pth")
    print(f"   - Core ML models saved to: coreml_models/")
    print(f"   - iOS files copied to: Modaics/Models/")
    print("\n🎉 Your fashion recommendation system is ready!")

if __name__ == "__main__":
    main()