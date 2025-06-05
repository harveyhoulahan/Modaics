"""
Modaics API Backend Service
FastAPI-based backend for handling server-side operations
"""

from fastapi import FastAPI, HTTPException, UploadFile, File, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import numpy as np
from datetime import datetime, timedelta
import torch
import torchvision.transforms as transforms
from PIL import Image
import io
import uuid
import firebase_admin
from firebase_admin import credentials, firestore, auth, storage
import redis
import json
from sklearn.neighbors import NearestNeighbors
import joblib
import logging
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Firebase
cred = credentials.Certificate("path/to/serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'modaics.appspot.com'
})

db = firestore.client()
bucket = storage.bucket()

# Initialize Redis for caching
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Security
security = HTTPBearer()

# Load ML models
class ModelManager:
    def __init__(self):
        self.model = None
        self.transform = None
        self.nn_index = None
        self.embeddings_cache = {}
        
    def load_models(self):
        """Load PyTorch model and similarity index"""
        try:
            # Load PyTorch model
            checkpoint = torch.load('models/best_fashion_model.pth', map_location='cpu')
            from modaics_training_pipeline import FashionFeatureExtractor
            
            self.model = FashionFeatureExtractor(
                num_categories=len(checkpoint['category_encoder'].classes_)
            )
            self.model.load_state_dict(checkpoint['model_state_dict'])
            self.model.eval()
            
            # Load similarity index
            self.nn_index = joblib.load('models/similarity_index.pkl')
            
            # Setup transforms
            self.transform = transforms.Compose([
                transforms.Resize(256),
                transforms.CenterCrop(224),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
            ])
            
            logger.info("Models loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load models: {e}")
            raise

model_manager = ModelManager()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    model_manager.load_models()
    yield
    # Shutdown
    redis_client.close()

# Create FastAPI app
app = FastAPI(
    title="Modaics API",
    description="Sustainable Fashion Marketplace API",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# Pydantic Models
# =====================================================

class UserCreate(BaseModel):
    email: str
    password: str
    username: str
    user_type: str = "consumer"
    location: Optional[str] = None

class UserResponse(BaseModel):
    uid: str
    email: str
    username: str
    user_type: str
    location: Optional[str]
    sustainability_points: int = 0
    created_at: datetime

class ItemCreate(BaseModel):
    name: str
    brand: str
    category: str
    size: str
    condition: str
    original_price: float
    listing_price: float
    description: str
    sustainability_info: Dict[str, Any]
    material_composition: List[Dict[str, Any]]
    color_tags: List[str]
    style_tags: List[str]

class ItemResponse(BaseModel):
    id: str
    name: str
    brand: str
    category: str
    size: str
    condition: str
    original_price: float
    listing_price: float
    description: str
    image_urls: List[str]
    sustainability_score: Dict[str, Any]
    owner_id: str
    created_at: datetime
    view_count: int = 0
    like_count: int = 0
    is_available: bool = True

class SimilarityRequest(BaseModel):
    item_id: str
    embedding: Optional[List[float]] = None
    top_k: int = 10

class SustainabilityScore(BaseModel):
    total_score: int = Field(..., ge=0, le=100)
    carbon_footprint: float
    water_usage: float
    is_recycled: bool
    is_certified: bool
    certifications: List[str]
    fibre_trace_verified: bool

# =====================================================
# Authentication
# =====================================================

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify Firebase auth token"""
    try:
        decoded_token = auth.verify_id_token(credentials.credentials)
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid authentication token")

# =====================================================
# User Endpoints
# =====================================================

@app.post("/api/users/register", response_model=UserResponse)
async def register_user(user_data: UserCreate):
    """Register a new user"""
    try:
        # Create Firebase auth user
        user = auth.create_user(
            email=user_data.email,
            password=user_data.password,
            display_name=user_data.username
        )
        
        # Create Firestore document
        user_doc = {
            "uid": user.uid,
            "email": user_data.email,
            "username": user_data.username,
            "user_type": user_data.user_type,
            "location": user_data.location,
            "sustainability_points": 0,
            "following": [],
            "followers": [],
            "liked_items": [],
            "wardrobe": [],
            "created_at": datetime.utcnow(),
            "is_verified": False
        }
        
        db.collection("users").document(user.uid).set(user_doc)
        
        return UserResponse(**user_doc)
    
    except Exception as e:
        logger.error(f"User registration failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/api/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, current_user=Depends(verify_token)):
    """Get user profile"""
    try:
        user_doc = db.collection("users").document(user_id).get()
        
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        return UserResponse(**user_doc.to_dict())
    
    except Exception as e:
        logger.error(f"Failed to get user: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/users/{user_id}/follow")
async def follow_user(user_id: str, current_user=Depends(verify_token)):
    """Follow/unfollow a user"""
    try:
        follower_id = current_user["uid"]
        
        # Update follower's following list
        follower_ref = db.collection("users").document(follower_id)
        follower_doc = follower_ref.get()
        
        if not follower_doc.exists:
            raise HTTPException(status_code=404, detail="Follower not found")
        
        following = follower_doc.to_dict().get("following", [])
        
        if user_id in following:
            # Unfollow
            following.remove(user_id)
            action = "unfollowed"
        else:
            # Follow
            following.append(user_id)
            action = "followed"
        
        follower_ref.update({"following": following})
        
        # Update target user's followers list
        target_ref = db.collection("users").document(user_id)
        target_doc = target_ref.get()
        
        if target_doc.exists:
            followers = target_doc.to_dict().get("followers", [])
            if action == "followed":
                followers.append(follower_id)
            else:
                followers.remove(follower_id) if follower_id in followers else None
            target_ref.update({"followers": followers})
        
        return {"message": f"Successfully {action} user", "action": action}
    
    except Exception as e:
        logger.error(f"Failed to follow/unfollow user: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# Item Endpoints
# =====================================================

@app.post("/api/items", response_model=ItemResponse)
async def create_item(
    item_data: ItemCreate,
    background_tasks: BackgroundTasks,
    current_user=Depends(verify_token)
):
    """Create a new fashion item listing"""
    try:
        item_id = str(uuid.uuid4())
        
        # Calculate sustainability score
        sustainability_score = calculate_sustainability_score(
            item_data.sustainability_info,
            item_data.material_composition
        )
        
        # Create item document
        item_doc = {
            "id": item_id,
            "name": item_data.name,
            "brand": item_data.brand,
            "category": item_data.category,
            "size": item_data.size,
            "condition": item_data.condition,
            "original_price": item_data.original_price,
            "listing_price": item_data.listing_price,
            "description": item_data.description,
            "image_urls": [],  # Will be updated after image upload
            "sustainability_score": sustainability_score,
            "material_composition": item_data.material_composition,
            "color_tags": item_data.color_tags,
            "style_tags": item_data.style_tags,
            "owner_id": current_user["uid"],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "view_count": 0,
            "like_count": 0,
            "is_available": True
        }
        
        # Save to Firestore
        db.collection("items").document(item_id).set(item_doc)
        
        # Update user's sustainability points in background
        background_tasks.add_task(
            update_user_sustainability_points,
            current_user["uid"],
            sustainability_score["total_score"]
        )
        
        return ItemResponse(**item_doc)
    
    except Exception as e:
        logger.error(f"Failed to create item: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/items/{item_id}/images")
async def upload_item_images(
    item_id: str,
    files: List[UploadFile] = File(...),
    current_user=Depends(verify_token)
):
    """Upload images for an item"""
    try:
        # Verify item ownership
        item_doc = db.collection("items").document(item_id).get()
        if not item_doc.exists:
            raise HTTPException(status_code=404, detail="Item not found")
        
        if item_doc.to_dict()["owner_id"] != current_user["uid"]:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        image_urls = []
        embeddings = []
        
        for idx, file in enumerate(files[:5]):  # Limit to 5 images
            # Upload to Firebase Storage
            blob_name = f"items/{item_id}/{idx}_{file.filename}"
            blob = bucket.blob(blob_name)
            
            contents = await file.read()
            blob.upload_from_string(contents, content_type=file.content_type)
            blob.make_public()
            
            image_urls.append(blob.public_url)
            
            # Extract embedding for first image
            if idx == 0:
                image = Image.open(io.BytesIO(contents)).convert('RGB')
                embedding = extract_embedding(image)
                embeddings.append(embedding)
        
        # Update item with image URLs and embedding
        update_data = {
            "image_urls": image_urls,
            "updated_at": datetime.utcnow()
        }
        
        if embeddings:
            update_data["embedding"] = embeddings[0]
        
        db.collection("items").document(item_id).update(update_data)
        
        return {"image_urls": image_urls, "message": "Images uploaded successfully"}
    
    except Exception as e:
        logger.error(f"Failed to upload images: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/items", response_model=List[ItemResponse])
async def get_items(
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_sustainability: Optional[int] = None,
    limit: int = 20,
    offset: int = 0
):
    """Get items with filters"""
    try:
        # Check cache first
        cache_key = f"items:{category}:{min_price}:{max_price}:{min_sustainability}:{limit}:{offset}"
        cached_result = redis_client.get(cache_key)
        
        if cached_result:
            return json.loads(cached_result)
        
        # Build query
        query = db.collection("items")
        
        if category:
            query = query.where("category", "==", category)
        
        if min_price is not None:
            query = query.where("listing_price", ">=", min_price)
        
        if max_price is not None:
            query = query.where("listing_price", "<=", max_price)
        
        if min_sustainability is not None:
            query = query.where("sustainability_score.total_score", ">=", min_sustainability)
        
        # Execute query
        items = []
        for doc in query.limit(limit).offset(offset).stream():
            items.append(ItemResponse(**doc.to_dict()))
        
        # Cache result for 5 minutes
        redis_client.setex(cache_key, 300, json.dumps([item.dict() for item in items]))
        
        return items
    
    except Exception as e:
        logger.error(f"Failed to get items: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/items/{item_id}/like")
async def like_item(item_id: str, current_user=Depends(verify_token)):
    """Like/unlike an item"""
    try:
        user_id = current_user["uid"]
        
        # Get user's liked items
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        liked_items = user_doc.to_dict().get("liked_items", [])
        
        # Get item
        item_ref = db.collection("items").document(item_id)
        item_doc = item_ref.get()
        
        if not item_doc.exists:
            raise HTTPException(status_code=404, detail="Item not found")
        
        like_count = item_doc.to_dict().get("like_count", 0)
        
        if item_id in liked_items:
            # Unlike
            liked_items.remove(item_id)
            like_count = max(0, like_count - 1)
            action = "unliked"
        else:
            # Like
            liked_items.append(item_id)
            like_count += 1
            action = "liked"
        
        # Update user and item
        user_ref.update({"liked_items": liked_items})
        item_ref.update({"like_count": like_count})
        
        return {"message": f"Successfully {action} item", "action": action, "like_count": like_count}
    
    except Exception as e:
        logger.error(f"Failed to like/unlike item: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# ML/Recommendation Endpoints
# =====================================================

@app.post("/api/recommendations/similar")
async def get_similar_items(request: SimilarityRequest):
    """Get similar items based on embeddings"""
    try:
        if request.embedding:
            # Use provided embedding
            query_embedding = np.array(request.embedding).reshape(1, -1)
        else:
            # Get embedding from item
            item_doc = db.collection("items").document(request.item_id).get()
            if not item_doc.exists:
                raise HTTPException(status_code=404, detail="Item not found")
            
            embedding = item_doc.to_dict().get("embedding")
            if not embedding:
                raise HTTPException(status_code=400, detail="Item has no embedding")
            
            query_embedding = np.array(embedding).reshape(1, -1)
        
        # Find similar items using the pre-built index
        distances, indices = model_manager.nn_index.kneighbors(
            query_embedding, 
            n_neighbors=request.top_k + 1  # +1 to exclude self
        )
        
        # Get item IDs from indices (this assumes you have a mapping)
        # For now, we'll query items by embedding similarity
        similar_items = []
        
        # In production, you'd have a better way to map indices to items
        # For now, return top items from database
        items_query = db.collection("items").limit(request.top_k).stream()
        for doc in items_query:
            if doc.id != request.item_id:
                similar_items.append(ItemResponse(**doc.to_dict()))
        
        return {"similar_items": similar_items, "count": len(similar_items)}
    
    except Exception as e:
        logger.error(f"Failed to get similar items: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/recommendations/extract-embedding")
async def extract_embedding_endpoint(file: UploadFile = File(...)):
    """Extract embedding from an uploaded image"""
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert('RGB')
        
        embedding = extract_embedding(image)
        
        return {"embedding": embedding, "dimension": len(embedding)}
    
    except Exception as e:
        logger.error(f"Failed to extract embedding: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# Analytics Endpoints
# =====================================================

@app.get("/api/analytics/sustainability-impact")
async def get_sustainability_impact(current_user=Depends(verify_token)):
    """Get user's sustainability impact metrics"""
    try:
        user_id = current_user["uid"]
        
        # Get user's items and transactions
        items_query = db.collection("items").where("owner_id", "==", user_id).stream()
        transactions_query = db.collection("transactions").where("buyer_id", "==", user_id).stream()
        
        total_water_saved = 0
        total_co2_saved = 0
        items_recycled = 0
        
        for item_doc in items_query:
            item = item_doc.to_dict()
            score = item.get("sustainability_score", {})
            total_water_saved += score.get("water_usage", 0)
            total_co2_saved += score.get("carbon_footprint", 0)
            if score.get("is_recycled", False):
                items_recycled += 1
        
        for trans_doc in transactions_query:
            trans = trans_doc.to_dict()
            if trans.get("type") == "swap":
                # Swaps save more resources
                total_water_saved += 2000  # Average water per item
                total_co2_saved += 5  # Average CO2 per item
        
        return {
            "water_saved_liters": total_water_saved,
            "co2_saved_kg": total_co2_saved,
            "items_recycled": items_recycled,
            "sustainability_points": current_user.get("sustainability_points", 0)
        }
    
    except Exception as e:
        logger.error(f"Failed to get sustainability impact: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/analytics/trending")
async def get_trending_items(limit: int = 10):
    """Get trending items based on views and likes"""
    try:
        # Calculate trending score (views + 2 * likes)
        # In production, use a more sophisticated algorithm
        
        trending_items = []
        items_query = db.collection("items")\
            .order_by("like_count", direction=firestore.Query.DESCENDING)\
            .limit(limit)\
            .stream()
        
        for doc in items_query:
            item_data = doc.to_dict()
            trending_score = item_data.get("view_count", 0) + 2 * item_data.get("like_count", 0)
            item_data["trending_score"] = trending_score
            trending_items.append(ItemResponse(**item_data))
        
        # Sort by trending score
        trending_items.sort(key=lambda x: x.dict().get("trending_score", 0), reverse=True)
        
        return {"trending_items": trending_items}
    
    except Exception as e:
        logger.error(f"Failed to get trending items: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# Helper Functions
# =====================================================

def calculate_sustainability_score(
    sustainability_info: Dict[str, Any],
    material_composition: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """Calculate comprehensive sustainability score"""
    
    base_score = 50
    
    # Material bonus
    for material in material_composition:
        if material.get("is_organic"):
            base_score += 10
        if material.get("is_recycled"):
            base_score += 15
    
    # Certification bonus
    certifications = sustainability_info.get("certifications", [])
    base_score += len(certifications) * 5
    
    # FibreTrace verification bonus
    if sustainability_info.get("fibre_trace_verified"):
        base_score += 20
    
    # Cap at 100
    total_score = min(100, base_score)
    
    # Calculate environmental impact (simplified)
    water_usage = 2000 * (1 - total_score / 100)  # Less water for sustainable items
    carbon_footprint = 5 * (1 - total_score / 100)  # Less CO2 for sustainable items
    
    return {
        "total_score": total_score,
        "carbon_footprint": carbon_footprint,
        "water_usage": water_usage,
        "is_recycled": sustainability_info.get("is_recycled", False),
        "is_certified": len(certifications) > 0,
        "certifications": certifications,
        "fibre_trace_verified": sustainability_info.get("fibre_trace_verified", False)
    }

def extract_embedding(image: Image.Image) -> List[float]:
    """Extract embedding from PIL image using the loaded model"""
    try:
        # Transform image
        image_tensor = model_manager.transform(image).unsqueeze(0)
        
        # Extract embedding
        with torch.no_grad():
            embedding = model_manager.model(image_tensor, return_embeddings=True)
            embedding = embedding.cpu().numpy().squeeze()
        
        return embedding.tolist()
    
    except Exception as e:
        logger.error(f"Failed to extract embedding: {e}")
        raise

async def update_user_sustainability_points(user_id: str, points: int):
    """Update user's sustainability points"""
    try:
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()
        
        if user_doc.exists:
            current_points = user_doc.to_dict().get("sustainability_points", 0)
            new_points = current_points + points
            user_ref.update({"sustainability_points": new_points})
            
            logger.info(f"Updated sustainability points for user {user_id}: {new_points}")
    
    except Exception as e:
        logger.error(f"Failed to update sustainability points: {e}")

# =====================================================
# Health Check
# =====================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "version": "1.0.0",
        "ml_models_loaded": model_manager.model is not None
    }

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to Modaics API",
        "documentation": "/docs",
        "health": "/health"
    }

# =====================================================
# Run the application
# =====================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )