"""
Find This Fit - Production FastAPI backend.
Handles image upload, embedding generation, and vector search.
"""
import base64
import logging
from contextlib import asynccontextmanager
from typing import List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

try:
    from .embeddings import embed_image, preload_models
    from .models import DepopItem, SearchRequest, SearchResponse
    from .search import search_similar
    from . import db
except ImportError:
    from embeddings import embed_image, preload_models
    from models import DepopItem, SearchRequest, SearchResponse
    from search import search_similar
    import db

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup and shutdown lifecycle.
    Preloads embedding models and initializes DB pool.
    """
    logger.info("Starting Find This Fit API...")
    
    # Initialize database pool
    await db.init_pool(min_size=2, max_size=10)
    logger.info("Database pool initialized")
    
    # Preload embedding models (avoids 5+ second delay on first request)
    preload_models()
    logger.info("Embedding models preloaded")
    
    yield
    
    # Cleanup on shutdown
    logger.info("Shutting down...")
    await db.close_pool()


app = FastAPI(
    title="Find This Fit API",
    version="1.0.0",
    description="Visual search for fashion items across resale marketplaces",
    lifespan=lifespan
)

# CORS for iOS Mini App and web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production: specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/search_by_image", response_model=SearchResponse)
async def search_by_image(payload: SearchRequest):
    """
    Upload an image and get visually similar Depop items.
    
    Flow:
    1. Decode base64 image
    2. Generate 768-dim embedding (OpenAI or CLIP)
    3. Query pgvector for nearest neighbors
    4. Return top 20 matches with deep links
    
    Typical latency: 100-500ms (50ms embedding + 10-50ms search + network)
    """
    try:
        image_bytes = base64.b64decode(payload.image_base64)
    except Exception as exc:
        logger.error(f"Base64 decode failed: {exc}")
        raise HTTPException(status_code=400, detail="Invalid base64 image data") from exc

    try:
        # Generate multimodal embedding (image only for photo search)
        # Note: We don't have text for user-uploaded photos,
        # but our database items have multimodal embeddings (image + title + description)
        embedding = embed_image(image_bytes, text=None)
        logger.info(f"Generated embedding: {len(embedding)} dimensions")
    except Exception as exc:
        logger.error(f"Embedding generation failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Embedding error: {str(exc)}") from exc

    try:
        # Vector search with HNSW index
        results = await search_similar(embedding, limit=20)
        logger.info(f"Found {len(results)} similar items")
    except Exception as exc:
        logger.error(f"Search failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Search error: {str(exc)}") from exc

    # Map to Pydantic models
    items: List[DepopItem] = []
    for r in results:
        distance_val = r.get("distance")
        items.append(
            DepopItem(
                id=r["id"],
                external_id=r.get("external_id"),
                title=r.get("title"),
                description=r.get("description"),
                price=float(r["price"]) if r.get("price") is not None else None,
                url=r.get("url"),
                image_url=r.get("image_url"),
                distance=float(distance_val) if distance_val is not None else None,
                redirect_url=r.get("redirect_url"),
                source=r.get("source"),
            )
        )
    
    return SearchResponse(items=items)


@app.post("/search_by_text", response_model=SearchResponse)
async def search_by_text(payload: dict):
    """
    Search for fashion items by text description.
    
    Flow:
    1. Extract text query from payload
    2. Generate text-only embedding using CLIP
    3. Query pgvector for nearest neighbors
    4. Return top 20 matches
    
    Example: "vintage black hoodie with graphic print"
    """
    query = payload.get("query", "").strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query text is required")
    
    try:
        # Generate text-only embedding (no image)
        # CLIP can embed text without an image
        embedding = embed_image(image_bytes=None, text=query)
        logger.info(f"Generated text embedding for: '{query}'")
    except Exception as exc:
        logger.error(f"Text embedding generation failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Embedding error: {str(exc)}") from exc

    try:
        # Vector search with HNSW index
        results = await search_similar(embedding, limit=20)
        logger.info(f"Found {len(results)} similar items for text query")
    except Exception as exc:
        logger.error(f"Search failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Search error: {str(exc)}") from exc

    # Map to Pydantic models
    items: List[DepopItem] = []
    for r in results:
        distance_val = r.get("distance")
        items.append(
            DepopItem(
                id=r["id"],
                external_id=r.get("external_id"),
                title=r.get("title"),
                description=r.get("description"),
                price=float(r["price"]) if r.get("price") is not None else None,
                url=r.get("url"),
                image_url=r.get("image_url"),
                distance=float(distance_val) if distance_val is not None else None,
                redirect_url=r.get("redirect_url"),
                source=r.get("source"),
            )
        )
    
    return SearchResponse(items=items)


@app.post("/search_combined", response_model=SearchResponse)
async def search_combined(payload: dict):
    """
    Search for fashion items using both image and text description.
    
    Flow:
    1. Decode base64 image and extract text query
    2. Generate multimodal embedding using both image and text
    3. Query pgvector for nearest neighbors
    4. Return top 20 matches
    
    This provides the most accurate results by combining visual and textual information.
    Example: image of a jacket + "vintage distressed denim"
    """
    query = payload.get("query", "").strip()
    image_base64 = payload.get("image_base64", "")
    
    if not query and not image_base64:
        raise HTTPException(
            status_code=400, 
            detail="At least one of 'query' or 'image_base64' is required"
        )
    
    image_bytes = None
    if image_base64:
        try:
            image_bytes = base64.b64decode(image_base64)
        except Exception as exc:
            logger.error(f"Base64 decode failed: {exc}")
            raise HTTPException(status_code=400, detail="Invalid base64 image data") from exc
    
    try:
        # Generate multimodal embedding with both image and text
        embedding = embed_image(image_bytes=image_bytes, text=query if query else None)
        logger.info(f"Generated combined embedding (image: {image_bytes is not None}, text: '{query}')")
    except Exception as exc:
        logger.error(f"Combined embedding generation failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Embedding error: {str(exc)}") from exc

    try:
        # Vector search with HNSW index
        results = await search_similar(embedding, limit=20)
        logger.info(f"Found {len(results)} similar items for combined query")
    except Exception as exc:
        logger.error(f"Search failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Search error: {str(exc)}") from exc

    # Map to Pydantic models
    items: List[DepopItem] = []
    for r in results:
        distance_val = r.get("distance")
        items.append(
            DepopItem(
                id=r["id"],
                external_id=r.get("external_id"),
                title=r.get("title"),
                description=r.get("description"),
                price=float(r["price"]) if r.get("price") is not None else None,
                url=r.get("url"),
                image_url=r.get("image_url"),
                distance=float(distance_val) if distance_val is not None else None,
                redirect_url=r.get("redirect_url"),
                source=r.get("source"),
            )
        )
    
    return SearchResponse(items=items)


@app.post("/analyze_image")
async def analyze_image(payload: dict):
    """
    AI-powered item analysis using CLIP embeddings + visual similarity.
    
    Analyzes uploaded images to extract:
    - Item name/type (from similar items in database)
    - Brand (from text in similar items)
    - Category (from clustering of similar items)
    - Estimated size (from similar items)
    - Condition (visual quality assessment)
    - Colors (from title/description keywords)
    - Materials (from similar items)
    - Estimated price (average of top 10 similar items)
    
    This uses your 25,677 item database for smart predictions!
    """
    image_base64 = payload.get("image", "")
    if not image_base64:
        raise HTTPException(status_code=400, detail="Image is required")
    
    try:
        image_bytes = base64.b64decode(image_base64)
    except Exception as exc:
        logger.error(f"Base64 decode failed: {exc}")
        raise HTTPException(status_code=400, detail="Invalid base64 image data") from exc
    
    try:
        # Generate CLIP embedding for uploaded image
        embedding = embed_image(image_bytes=image_bytes, text=None)
        
        # STEP 1: Use zero-shot classification on the actual image
        # This analyzes the ACTUAL image, not similar items
        # Reuse the CLIP model from embeddings module for efficiency
        from sentence_transformers import util
        import numpy as np
        from PIL import Image as PILImage
        from io import BytesIO
        
        try:
            from .embeddings import _get_clip_model
        except ImportError:
            from embeddings import _get_clip_model
        
        model = _get_clip_model()
        uploaded_image = PILImage.open(BytesIO(image_bytes)).convert("RGB")
        
        # STEP 0: GPT-4 Vision for brand AND color detection (if API key available)
        # Much better than OCR for reading brand names and more accurate for colors
        detected_text_on_image = ""
        gpt4_detected_color = ""
        try:
            import os
            from openai import OpenAI
            
            openai_key = os.getenv("OPENAI_API_KEY")
            
            if openai_key:
                client = OpenAI(api_key=openai_key)
                
                # Encode image for GPT-4 Vision
                import base64 as b64_module
                image_b64 = b64_module.b64encode(image_bytes).decode('utf-8')
                
                # Ask GPT-4 to analyze the image comprehensively
                response = client.chat.completions.create(
                    model="gpt-4o",  # Use full gpt-4o for better vision
                    messages=[
                        {
                            "role": "user",
                            "content": [
                                {
                                    "type": "text",
                                    "text": """Analyze this fashion item carefully and provide:

1. BRAND: Look for ANY text, logos, or brand identifiers (embroidered, printed, on tags, etc.)
   Common brands: Nike, Adidas, Supreme, Palace, Prada, Gucci, Louis Vuitton, Balenciaga,
   Carhartt, Dickies, Champion, North Face, Patagonia, Ralph Lauren, Tommy Hilfiger, Levi's, etc.

2. PRIMARY COLOR: What is the MAIN color of this item? Be specific - distinguish between:
   - Black vs Navy vs Dark Gray
   - White vs Cream vs Beige
   - Red vs Burgundy vs Maroon

Reply in this exact format:
BRAND: [brand name or "unknown"]
COLOR: [exact primary color]

Example responses:
BRAND: Prada
COLOR: Black

or

BRAND: Nike  
COLOR: White

Be confident and specific. If you see embroidery, logos, or text - identify the brand!"""
                                },
                                {
                                    "type": "image_url",
                                    "image_url": {
                                        "url": f"data:image/jpeg;base64,{image_b64}",
                                        "detail": "high"  # High detail for better recognition
                                    }
                                }
                            ]
                        }
                    ],
                    max_tokens=150,
                    temperature=0
                )
                
                gpt4_response = response.choices[0].message.content.strip()
                logger.info(f"🔍 GPT-4 Vision response:\n{gpt4_response}")
                
                # Parse the structured response
                detected_text_on_image = ""
                gpt4_detected_color = ""
                
                for line in gpt4_response.split('\n'):
                    line = line.strip()
                    if line.startswith('BRAND:'):
                        brand_text = line.replace('BRAND:', '').strip().lower()
                        if brand_text not in ['unknown', 'none', 'n/a', '']:
                            detected_text_on_image = brand_text
                    elif line.startswith('COLOR:'):
                        color_text = line.replace('COLOR:', '').strip()
                        if color_text not in ['unknown', 'none', 'n/a', '']:
                            gpt4_detected_color = color_text
                
                if detected_text_on_image:
                    logger.info(f"✅ GPT-4 detected brand: {detected_text_on_image}")
                if gpt4_detected_color:
                    logger.info(f"🎨 GPT-4 detected color: {gpt4_detected_color}")
                    
        except Exception as e:
            logger.warning(f"GPT-4 Vision error: {e}")
            detected_text_on_image = ""
            gpt4_detected_color = ""
        
        # Zero-shot category classification - HIGHLY GRANULAR
        category_labels = [
            "bomber jacket flight jacket ma-1",
            "parka winter coat hooded coat",
            "denim jacket jean jacket trucker jacket",
            "blazer suit jacket sport coat",
            "leather jacket moto jacket biker jacket",
            "windbreaker track jacket coach jacket",
            "hoodie hooded sweatshirt pullover hoodie zip-up hoodie",
            "cardigan button-up sweater knit cardigan",
            "crewneck sweater pullover sweater",
            "v-neck sweater",
            "turtleneck sweater roll neck",
            "fleece jacket fleece pullover",
            "t-shirt tee short sleeve top",
            "long sleeve shirt button-up oxford chambray",
            "polo shirt collared shirt",
            "tank top sleeveless shirt muscle tee",
            "blouse feminine top",
            "dress gown maxi midi mini dress",
            "jeans denim pants 5-pocket",
            "chinos khakis dress pants trousers",
            "cargo pants utility pants tactical pants",
            "joggers sweatpants track pants",
            "shorts bermuda shorts",
            "skirt midi skirt mini skirt",
            "running shoes athletic sneakers trainers",
            "basketball sneakers high-top sneakers",
            "casual sneakers low-top sneakers canvas shoes",
            "boots leather boots work boots chelsea boots",
            "sandals slides flip-flops",
            "backpack rucksack bag",
            "tote bag shoulder bag handbag",
            "crossbody bag messenger bag",
            "hat cap beanie snapback"
        ]
        category_names = [
            "bomber_jacket", "parka", "denim_jacket", "blazer", "leather_jacket", 
            "windbreaker", "hoodie", "cardigan", "crewneck_sweater", "vneck_sweater",
            "turtleneck", "fleece", "tshirt", "shirt", "polo", "tank",
            "blouse", "dress", "jeans", "chinos", "cargo_pants", "joggers",
            "shorts", "skirt", "running_shoes", "basketball_sneakers", 
            "casual_sneakers", "boots", "sandals", "backpack", "tote_bag",
            "crossbody_bag", "hat"
        ]
        
        # Encode image and category labels
        image_embedding = model.encode(uploaded_image, convert_to_tensor=True)
        text_embeddings = model.encode(category_labels, convert_to_tensor=True)
        
        # Calculate similarity
        similarities = util.cos_sim(image_embedding, text_embeddings)[0]
        best_category_idx = similarities.argmax().item()
        detected_category_type = category_names[best_category_idx]
        category_confidence = float(similarities[best_category_idx])
        
        # Map to broad categories for compatibility
        category_mapping = {
            "bomber_jacket": "outerwear",
            "parka": "outerwear",
            "denim_jacket": "outerwear",
            "blazer": "outerwear",
            "leather_jacket": "outerwear",
            "windbreaker": "outerwear",
            "hoodie": "outerwear",
            "cardigan": "outerwear",
            "crewneck_sweater": "outerwear",
            "vneck_sweater": "outerwear",
            "turtleneck": "outerwear",
            "fleece": "outerwear",
            "tshirt": "tops",
            "shirt": "tops",
            "polo": "tops",
            "tank": "tops",
            "blouse": "tops",
            "dress": "dresses",
            "jeans": "bottoms",
            "chinos": "bottoms",
            "cargo_pants": "bottoms",
            "joggers": "bottoms",
            "shorts": "bottoms",
            "skirt": "bottoms",
            "running_shoes": "shoes",
            "basketball_sneakers": "shoes",
            "casual_sneakers": "shoes",
            "boots": "shoes",
            "sandals": "shoes",
            "backpack": "bags",
            "tote_bag": "bags",
            "crossbody_bag": "bags",
            "hat": "accessories"
        }
        category = category_mapping.get(detected_category_type, "tops")
        
        # Zero-shot color classification - ULTRA SIMPLE (just color words)
        # Debug showed simpler is better: "white" scores 0.2279 vs "white clothing" 0.2250
        color_labels = [
            "black", "white", "gray", "red", "blue", "navy",
            "green", "yellow", "orange", "pink", "purple", 
            "brown", "multicolor"
        ]
        color_names = [
            "Black", "White", "Gray", "Red", "Blue", "Navy",
            "Green", "Yellow", "Orange", "Pink", "Purple", 
            "Brown", "Multicolor"
        ]
        
        color_embeddings = model.encode(color_labels, convert_to_tensor=True)
        color_similarities = util.cos_sim(image_embedding, color_embeddings)[0]
        
        # Debug showed confidence scores are LOW (0.22-0.27 range)
        # We need to pick the BEST one and ignore weak secondary colors
        top_color_indices = color_similarities.argsort(descending=True)[:3]
        
        detected_colors = []
        color_confidences = []
        
        # Override with GPT-4 color if available (more accurate than CLIP for colors)
        if gpt4_detected_color:
            detected_colors.append(gpt4_detected_color.title())
            color_confidences.append(0.95)  # High confidence for GPT-4
        else:
            # Fall back to CLIP color detection
            # ALWAYS take the top color (even if low confidence)
            top_idx = top_color_indices[0]
            top_color = color_names[top_idx.item()]
            top_conf = float(color_similarities[top_idx])
            detected_colors.append(top_color)
            color_confidences.append(top_conf)
            
            # Only add secondary colors if they're VERY close to primary (within 0.02)
            # This prevents random weak secondary colors
            for i in range(1, 3):
                idx = top_color_indices[i]
                conf = float(color_similarities[idx])
                # Only add if very close to primary AND above 0.24 absolute threshold
                if (top_conf - conf) < 0.02 and conf > 0.24:
                    detected_colors.append(color_names[idx.item()])
                    color_confidences.append(conf)
        
        # STEP 1B: Pattern detection using zero-shot classification
        pattern_labels = [
            "solid plain single color no pattern",
            "striped horizontal stripes vertical stripes",
            "graphic print logo text typography",
            "floral flowers botanical garden print",
            "plaid checkered tartan gingham",
            "camouflage camo military print",
            "tie-dye dyed marble swirl",
            "polka dot dotted spotted",
            "animal print leopard zebra snake",
            "abstract geometric shapes",
            "denim wash stonewash distressed faded",
            "embroidered stitched embellished"
        ]
        pattern_names = [
            "Solid", "Striped", "Graphic", "Floral", "Plaid", 
            "Camo", "Tie-Dye", "Polka Dot", "Animal Print", 
            "Abstract", "Denim Wash", "Embroidered"
        ]
        
        pattern_embeddings = model.encode(pattern_labels, convert_to_tensor=True)
        pattern_similarities = util.cos_sim(image_embedding, pattern_embeddings)[0]
        
        # Get top pattern
        best_pattern_idx = pattern_similarities.argmax().item()
        detected_pattern = pattern_names[best_pattern_idx]
        pattern_confidence = float(pattern_similarities[best_pattern_idx])
        
        # STEP 2: Find similar items for brand/price estimation
        results = await search_similar(embedding, limit=10)
        
        if not results:
            logger.warning("No similar items found in database")
            # Build item name from detected attributes
            name_parts = [detected_colors[0] if detected_colors else ""]
            if detected_pattern and detected_pattern.lower() != "solid":
                name_parts.append(detected_pattern)
            name_parts.append(detected_category_type.replace("_", " ").title())
            detected_item_name = " ".join([p for p in name_parts if p])
            
            return {
                "detected_item": detected_item_name,
                "likely_brand": "",
                "category": category,
                "specific_category": detected_category_type,
                "estimated_size": "M",
                "estimated_condition": "excellent",
                "description": f"{detected_item_name} in excellent condition",
                "colors": detected_colors[:3],
                "pattern": detected_pattern,
                "materials": [],
                "estimated_price": None,
                "confidence": round(category_confidence, 2),
                "confidence_scores": {
                    "category": round(category_confidence, 2),
                    "colors": [round(c, 2) for c in color_confidences],
                    "pattern": round(pattern_confidence, 2),
                    "brand": 0.0
                }
            }
        
        # Analyze top matches for price estimation
        titles = [r.get("title", "") for r in results if r.get("title")]
        descriptions = [r.get("description", "") for r in results if r.get("description")]
        prices = [float(r["price"]) for r in results if r.get("price") is not None]
        
        # Combine all text for material/size/brand extraction
        all_text = " ".join(titles + descriptions).lower()
        
        # Add GPT-4 Vision detected text if available (HIGHEST PRIORITY for brands)
        if detected_text_on_image:
            all_text = detected_text_on_image + " " + all_text
        
        # BRAND DETECTION - TRIPLE HYBRID (GPT-4 Direct > Text Mining > Visual)
        # Step 1: Check if GPT-4 Vision found brand text directly on the image
        gpt4_brand = ""
        if detected_text_on_image:
            # Define comprehensive brand list for matching
            brand_keywords = {
                # Luxury
                "prada": "Prada", "gucci": "Gucci", "louis vuitton": "Louis Vuitton", "lv": "Louis Vuitton",
                "chanel": "Chanel", "dior": "Dior", "balenciaga": "Balenciaga", "versace": "Versace",
                "fendi": "Fendi", "burberry": "Burberry", "saint laurent": "Saint Laurent", "ysl": "YSL",
                "hermes": "Hermès", "hermès": "Hermès", "givenchy": "Givenchy", "valentino": "Valentino",
                # Streetwear
                "supreme": "Supreme", "palace": "Palace", "bape": "BAPE", "a bathing ape": "BAPE",
                "stussy": "Stüssy", "stüssy": "Stüssy", "off-white": "Off-White", "off white": "Off-White",
                "kith": "Kith", "anti social social club": "Anti Social Social Club", "assc": "ASSC",
                # Athletic
                "nike": "Nike", "adidas": "Adidas", "puma": "Puma", "reebok": "Reebok",
                "new balance": "New Balance", "under armour": "Under Armour", "asics": "ASICS",
                "vans": "Vans", "converse": "Converse", "champion": "Champion", "fila": "Fila",
                # Contemporary
                "ami paris": "AMI Paris", "ami": "AMI Paris", "acne studios": "Acne Studios", "acne": "Acne Studios",
                "a.p.c": "A.P.C.", "apc": "A.P.C.", "stone island": "Stone Island",
                "cp company": "C.P. Company", "c.p. company": "C.P. Company",
                "carhartt": "Carhartt", "dickies": "Dickies", "carhartt wip": "Carhartt WIP",
                "polo ralph lauren": "Polo Ralph Lauren", "ralph lauren": "Ralph Lauren", "polo": "Polo Ralph Lauren",
                "tommy hilfiger": "Tommy Hilfiger", "tommy": "Tommy Hilfiger", "lacoste": "Lacoste",
                "patagonia": "Patagonia", "north face": "The North Face", "the north face": "The North Face",
                "columbia": "Columbia", "arcteryx": "Arc'teryx", "arc'teryx": "Arc'teryx",
                # Fast fashion
                "zara": "Zara", "h&m": "H&M", "hm": "H&M", "uniqlo": "Uniqlo", "gap": "Gap",
                "old navy": "Old Navy", "forever 21": "Forever 21", "primark": "Primark",
                # Denim
                "levi's": "Levi's", "levis": "Levi's", "levi": "Levi's", "wrangler": "Wrangler", "lee": "Lee",
                "diesel": "Diesel", "true religion": "True Religion", "g-star": "G-Star"
            }
            
            # First, try direct match (GPT-4 might return the exact brand name)
            detected_lower = detected_text_on_image.lower().strip()
            
            # Check for direct brand name match
            for keyword, brand_name in brand_keywords.items():
                if keyword == detected_lower or keyword in detected_lower or detected_lower in keyword:
                    gpt4_brand = brand_name
                    logger.info(f"✅ GPT-4 Vision identified brand: {brand_name}")
                    break
            
            # If no match, GPT-4 might have returned a brand we recognize
            if not gpt4_brand and len(detected_text_on_image) > 2:
                # Capitalize first letter of each word for brands not in our list
                gpt4_brand = detected_text_on_image.title()
                logger.info(f"✅ GPT-4 Vision detected unknown brand: {gpt4_brand}")
        
        # Step 2: Try zero-shot for visually distinctive brands only
        distinctive_brand_labels = [
            # Only brands with very distinctive visual styles
            "supreme box logo red white streetwear",
            "nike swoosh checkmark athletic",
            "adidas three stripes trefoil athletic",
            "gucci gg pattern luxury italian",
            "louis vuitton lv monogram pattern",
            "polo ralph lauren polo pony preppy",
            "tommy hilfiger flag logo red white blue",
            "champion c logo athletic",
            "carhartt workwear utility tan brown",
            "patagonia outdoor fleece mountain",
            "north face outdoor technical black",
            "vans skateboard checkerboard",
            "converse chuck taylor all-star canvas",
            "no clear brand logo generic plain"
        ]
        distinctive_brand_names = [
            "Supreme", "Nike", "Adidas", "Gucci", "Louis Vuitton",
            "Polo Ralph Lauren", "Tommy Hilfiger", "Champion", 
            "Carhartt", "Patagonia", "The North Face", 
            "Vans", "Converse", ""
        ]
        
        brand_embeddings = model.encode(distinctive_brand_labels, convert_to_tensor=True)
        brand_similarities = util.cos_sim(image_embedding, brand_embeddings)[0]
        
        best_brand_idx = brand_similarities.argmax().item()
        visual_brand = distinctive_brand_names[best_brand_idx]
        visual_brand_confidence = float(brand_similarities[best_brand_idx])
        
        # Step 3: Text mining from similar items for non-distinctive brands
        # This works better for brands without obvious visual markers
        text_brands = {
            # Luxury (less visually distinctive)
            "prada", "balenciaga", "versace", "fendi", "burberry", 
            "saint laurent", "ysl", "dior", "chanel", "hermes",
            # Streetwear
            "supreme", "palace", "bape", "stussy", "off-white",
            # Athletic
            "nike", "adidas", "puma", "reebok", "new balance", 
            "under armour", "asics",
            # Contemporary
            "ami", "ami paris", "acne studios", "apc", "a.p.c.",
            "stone island", "cp company", "c.p. company",
            # Common brands
            "polo", "polo ralph lauren", "ralph lauren", "tommy hilfiger",
            "lacoste", "carhartt", "dickies", "champion",
            "patagonia", "north face", "columbia",
            "vans", "converse",
            # Fast fashion
            "zara", "h&m", "uniqlo", "gap",
            # Denim
            "levi's", "levis", "wrangler", "lee"
        }
        
        text_brand = ""
        text_brand_count = 0
        for brand in text_brands:
            count = all_text.count(brand)
            if count > text_brand_count:
                text_brand_count = count
                text_brand = brand
        
        # Step 4: Decide which brand to use (PRIORITY: GPT-4 > Text Mining > Visual)
        # GPT-4 Vision reading actual text on clothing is most accurate
        # Only return a brand if we're confident - otherwise return empty string
        if gpt4_brand:
            detected_brand = gpt4_brand
            brand_confidence = 0.95  # Very high confidence for GPT-4 Vision
        elif text_brand_count >= 3:  # Brand mentioned at least 3 times (raised from 2 for higher confidence)
            detected_brand = text_brand.title().replace("Ami Paris", "AMI Paris").replace("Ysl", "YSL").replace("Apc", "A.P.C.")
            brand_confidence = min(0.85, 0.6 + (text_brand_count * 0.08))  # Higher confidence for text
        elif visual_brand_confidence > 0.40 and visual_brand:  # Raised threshold to 0.40 (from 0.30)
            # Only use visual for VERY confident matches (distinctive logos like Nike swoosh, Adidas stripes)
            detected_brand = visual_brand
            brand_confidence = visual_brand_confidence
        else:
            # Not confident enough - don't guess
            detected_brand = ""
            brand_confidence = 0.0
            logger.info("⚠️ Brand confidence too low - not returning a brand guess")
        
        # NOTE: Category, color, and pattern now come from zero-shot classification above
        
        # MATERIAL DETECTION from similar items
        material_keywords = {
            "cotton": ["cotton", "jersey"],
            "denim": ["denim", "jean"],
            "leather": ["leather", "suede"],
            "wool": ["wool", "cashmere", "merino"],
            "silk": ["silk", "satin"],
            "polyester": ["polyester", "poly"],
            "linen": ["linen"],
            "nylon": ["nylon"],
            "canvas": ["canvas"]
        }
        
        detected_materials = []
        for material, keywords in material_keywords.items():
            if any(kw in all_text for kw in keywords):
                detected_materials.append(material.title())
        
        # BUILD DETECTED ITEM NAME using detected attributes
        name_parts = []
        
        # Add primary color
        if detected_colors:
            name_parts.append(detected_colors[0])
        
        # Add pattern if not solid
        if detected_pattern and detected_pattern.lower() != "solid":
            name_parts.append(detected_pattern)
        
        # Add specific category type (e.g., "Bomber Jacket" not just "Outerwear")
        category_display = detected_category_type.replace("_", " ").title()
        name_parts.append(category_display)
        
        detected_item = " ".join(name_parts) if name_parts else "Fashion Item"
        
        # SIZE ESTIMATION - From similar items
        size_keywords = ["xs", "s", "m", "l", "xl", "xxl"]
        size_counts = {size: all_text.count(size) for size in size_keywords}
        if size_counts:
            estimated_size = max(size_counts, key=lambda k: size_counts[k]).upper()
        else:
            estimated_size = "M"
        
        # CONDITION ESTIMATION - Based on distance to similar items
        top_match = results[0]
        distance = top_match.get("distance", 1.0)
        
        if distance < 0.3:
            estimated_condition = "excellent"
        elif distance < 0.5:
            estimated_condition = "good"
        else:
            estimated_condition = "fair"
        
        # PRICE ESTIMATION - Average of top similar items, filter outliers
        if prices:
            # Remove outliers (anything > 3 standard deviations)
            import statistics
            if len(prices) > 3:
                mean = statistics.mean(prices)
                stdev = statistics.stdev(prices)
                filtered_prices = [p for p in prices if abs(p - mean) < 3 * stdev]
                estimated_price = round(statistics.mean(filtered_prices), 2) if filtered_prices else mean
            else:
                estimated_price = round(statistics.mean(prices), 2)
        else:
            estimated_price = None
        
        # DESCRIPTION GENERATION - Simple and factual
        description_parts = []
        
        # Brand
        if detected_brand:
            description_parts.append(detected_brand)
        
        # Item name (e.g., "Navy Windbreaker")
        description_parts.append(detected_item)
        
        # Size
        if estimated_size:
            description_parts.append(f"Size {estimated_size}")
        
        # Condition
        if estimated_condition:
            description_parts.append(estimated_condition.title())
        
        # Simple, comma-separated format: "Starter Navy Windbreaker, Size M, Excellent"
        description = ", ".join(description_parts) + "."
        
        # CONFIDENCE SCORE - Based on CLIP distance
        overall_confidence = max(0.0, min(1.0, 1.0 - distance))
        
        analysis = {
            "detected_item": detected_item,
            "likely_brand": detected_brand,
            "category": category,
            "specific_category": detected_category_type,  # More granular
            "estimated_size": estimated_size,
            "estimated_condition": estimated_condition,
            "description": description,
            "colors": detected_colors[:3],
            "pattern": detected_pattern,
            "materials": detected_materials[:3],
            "estimated_price": estimated_price,
            "confidence": round(overall_confidence, 2),
            # Detailed confidence scores for each attribute
            "confidence_scores": {
                "category": round(category_confidence, 2),
                "colors": [round(c, 2) for c in color_confidences],
                "pattern": round(pattern_confidence, 2),
                "brand": round(brand_confidence, 2)
            }
        }
        
        logger.info(f"AI analysis: {detected_item} ({detected_brand}) - {overall_confidence:.0%} confidence")
        return analysis
        
    except Exception as exc:
        logger.error(f"AI analysis failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Analysis error: {str(exc)}") from exc


@app.post("/generate_description")
async def generate_description(payload: dict):
    """
    Generate a professional product description using GPT-4 Vision API.
    
    Requires OPENAI_API_KEY environment variable to be set.
    Falls back to template-based generation if API key not available.
    """
    try:
        import os
        
        # Extract parameters
        image_base64 = payload.get("image")
        category = payload.get("category", "clothing item")
        brand = payload.get("brand", "")
        colors = payload.get("colors", [])
        condition = payload.get("condition", "Good")
        materials = payload.get("materials", [])
        size = payload.get("size", "")
        
        if not image_base64:
            raise HTTPException(status_code=400, detail="No image provided")
        
        # Try GPT-4 Vision API first
        openai_key = os.getenv("OPENAI_API_KEY")
        
        if openai_key:
            try:
                from openai import OpenAI
                client = OpenAI(api_key=openai_key)
                
                # Build context for GPT-4
                context_parts = []
                if colors:
                    context_parts.append(f"{' '.join(colors)}")
                if brand:
                    context_parts.append(f"from {brand}")
                context_parts.append(category)
                
                context = " ".join(context_parts)
                
                # Call GPT-4 Vision for simple, factual description
                response = client.chat.completions.create(
                    model="gpt-4o",
                    messages=[
                        {
                            "role": "user",
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"""Create a SHORT, simple product description for this {context}.

Requirements:
- Maximum 2 sentences
- Just state the facts: what it is, condition, key features
- NO marketing language or hype
- NO emojis
- Professional but concise

Examples:
✅ "Navy windbreaker jacket in excellent condition. Features zip closure and side pockets."
✅ "Black leather sneakers, size 42. Minimal wear, clean and ready to wear."
✅ "Vintage Levi's 501 jeans in medium wash. Good condition with authentic distressing."

Condition: {condition}

Write a simple description:"""
                                },
                                {
                                    "type": "image_url",
                                    "image_url": {
                                        "url": f"data:image/jpeg;base64,{image_base64}"
                                    }
                                }
                            ]
                        }
                    ],
                    max_tokens=100,
                    temperature=0.3  # Lower temperature for more factual descriptions
                )
                
                description = response.choices[0].message.content.strip()
                logger.info(f"GPT-4 Vision generated fun description: {description[:50]}...")
                
                return {
                    "description": description,
                    "method": "gpt4_vision",
                    "confidence": 0.95
                }
                
            except Exception as e:
                logger.warning(f"GPT-4 Vision failed, falling back to templates: {e}")
        
        # Fallback: Simple template-based generation
        logger.info("Using simple template-based description generation")
        
        # Build simple, factual description
        parts = []
        
        # Item identification
        if brand and colors:
            color_str = colors[0] if colors else ""
            parts.append(f"{brand} {color_str} {category}".strip())
        elif colors:
            parts.append(f"{colors[0]} {category}")
        elif brand:
            parts.append(f"{brand} {category}")
        else:
            parts.append(category.title())
        
        # Size
        if size:
            parts.append(f"Size {size}")
        
        # Condition
        parts.append(f"{condition} condition")
        
        # Material (if available)
        if materials:
            parts.append(f"{materials[0]} material")
        
        # Simple format: "Brand Color Item, Size X, Condition, Material"
        description = ", ".join(parts) + "."
        
        return {
            "description": description,
            "method": "template",
            "confidence": 0.75
        }
        
    except Exception as exc:
        logger.error(f"Description generation failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Description error: {str(exc)}") from exc


@app.post("/add_item")
async def add_item(payload: dict):
    """
    Add a new item to the database with CLIP embeddings.
    
    Accepts:
    - image_base64: Base64 encoded item image
    - title: Item title/name
    - description: Item description
    - price: Listing price
    - brand: Brand name
    - category: Category
    - size: Size
    - condition: Condition
    - owner_id: User ID who owns the item
    - source: Source (e.g., "modaics")
    
    Generates CLIP embeddings and stores in database for AI search.
    """
    try:
        # Extract required fields
        image_base64 = payload.get("image_base64")
        title = payload.get("title", "")
        description = payload.get("description", "")
        price = payload.get("price")
        
        if not image_base64:
            raise HTTPException(status_code=400, detail="Image is required")
        if not title:
            raise HTTPException(status_code=400, detail="Title is required")
        
        # Extract optional fields
        brand = payload.get("brand", "")
        category = payload.get("category", "")
        size = payload.get("size", "")
        condition = payload.get("condition", "")
        owner_id = payload.get("owner_id", "")
        source = payload.get("source", "modaics")
        image_url = payload.get("image_url", "")
        
        # Decode image
        try:
            image_bytes = base64.b64decode(image_base64)
        except Exception as exc:
            logger.error(f"Base64 decode failed: {exc}")
            raise HTTPException(status_code=400, detail="Invalid base64 image data") from exc
        
        # Generate multimodal CLIP embedding (image + text)
        # Combine title and description for better semantic search
        text_for_embedding = f"{title}. {description}"
        try:
            embedding = embed_image(image_bytes=image_bytes, text=text_for_embedding)
            logger.info(f"Generated embedding for new item: {title}")
        except Exception as exc:
            logger.error(f"Embedding generation failed: {exc}")
            raise HTTPException(status_code=500, detail=f"Embedding error: {str(exc)}") from exc
        
        # Insert into database
        try:
            # Build full item data
            item_data = {
                "title": title,
                "description": description,
                "price": price,
                "brand": brand,
                "category": category,
                "size": size,
                "condition": condition,
                "owner_id": owner_id,
                "source": source,
                "image_url": image_url,
                "embedding": embedding
            }
            
            # Insert into DB and get the new ID
            item_id = await db.insert_item(item_data)
            logger.info(f"Successfully added item with ID: {item_id}")
            
            return {
                "success": True,
                "item_id": item_id,
                "message": "Item added successfully with CLIP embeddings"
            }
            
        except Exception as exc:
            logger.error(f"Database insertion failed: {exc}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(exc)}") from exc
        
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Add item failed: {exc}")
        raise HTTPException(status_code=500, detail=f"Server error: {str(exc)}") from exc


# ============================================================================
# SKETCHBOOK API ENDPOINTS
# ============================================================================

try:
    from . import sketchbook
except ImportError:
    import sketchbook


@app.get("/sketchbook/brand/{brand_id}")
async def get_brand_sketchbook(brand_id: str):
    """Get a brand's sketchbook (creates one if doesn't exist)."""
    try:
        result = await sketchbook.get_sketchbook_by_brand(brand_id)
        if not result:
            raise HTTPException(status_code=404, detail="Sketchbook not found")
        return result
    except Exception as exc:
        logger.error(f"Failed to get sketchbook for brand {brand_id}: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.put("/sketchbook/{sketchbook_id}/settings")
async def update_sketchbook(sketchbook_id: int, payload: dict):
    """Update sketchbook settings (brand only)."""
    try:
        result = await sketchbook.update_sketchbook_settings(
            sketchbook_id=sketchbook_id,
            title=payload.get("title"),
            description=payload.get("description"),
            access_policy=payload.get("access_policy"),
            membership_rule=payload.get("membership_rule"),
            min_spend_amount=payload.get("min_spend_amount"),
            min_spend_window_months=payload.get("min_spend_window_months")
        )
        
        if not result:
            raise HTTPException(status_code=404, detail="Sketchbook not found")
        
        return result
    except Exception as exc:
        logger.error(f"Failed to update sketchbook {sketchbook_id}: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/sketchbook/{sketchbook_id}/posts")
async def get_posts(sketchbook_id: int, user_id: str = None, limit: int = 50):
    """Get posts from a sketchbook, filtered by user access."""
    try:
        posts = await sketchbook.get_sketchbook_posts(sketchbook_id, user_id, limit)
        return {"posts": posts}
    except Exception as exc:
        logger.error(f"Failed to get posts for sketchbook {sketchbook_id}: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/sketchbook/{sketchbook_id}/posts")
async def create_post(sketchbook_id: int, payload: dict):
    """Create a new sketchbook post (brand only)."""
    try:
        from datetime import datetime
        
        # Parse poll_closes_at if present
        poll_closes_at = None
        if payload.get("poll_closes_at"):
            poll_closes_at = datetime.fromisoformat(payload["poll_closes_at"].replace("Z", "+00:00"))
        
        result = await sketchbook.create_sketchbook_post(
            sketchbook_id=sketchbook_id,
            author_user_id=payload["author_user_id"],
            post_type=payload["post_type"],
            title=payload["title"],
            body=payload.get("body"),
            media=payload.get("media"),
            tags=payload.get("tags"),
            visibility=payload.get("visibility", "public"),
            poll_question=payload.get("poll_question"),
            poll_options=payload.get("poll_options"),
            poll_closes_at=poll_closes_at,
            event_id=payload.get("event_id"),
            event_highlight=payload.get("event_highlight")
        )
        
        if not result:
            raise HTTPException(status_code=500, detail="Failed to create post")
        
        return result
    except Exception as exc:
        logger.error(f"Failed to create post: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.delete("/sketchbook/posts/{post_id}")
async def delete_post(post_id: int, user_id: str):
    """Delete a post (author only)."""
    try:
        success = await sketchbook.delete_sketchbook_post(post_id, user_id)
        if not success:
            raise HTTPException(status_code=404, detail="Post not found or unauthorized")
        return {"success": True}
    except Exception as exc:
        logger.error(f"Failed to delete post {post_id}: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/sketchbook/{sketchbook_id}/membership/{user_id}")
async def check_membership_status(sketchbook_id: int, user_id: str):
    """Check if user has active membership."""
    try:
        membership = await sketchbook.check_membership(sketchbook_id, user_id)
        return membership if membership else {"status": "none"}
    except Exception as exc:
        logger.error(f"Failed to check membership: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/sketchbook/{sketchbook_id}/membership")
async def request_sketchbook_membership(sketchbook_id: int, payload: dict):
    """Request or grant membership."""
    try:
        result = await sketchbook.request_membership(
            sketchbook_id=sketchbook_id,
            user_id=payload["user_id"],
            join_source=payload.get("join_source", "requestApproved")
        )
        
        if not result:
            raise HTTPException(status_code=500, detail="Failed to create membership")
        
        return result
    except Exception as exc:
        logger.error(f"Failed to request membership: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/sketchbook/{sketchbook_id}/spend-eligibility/{user_id}")
async def check_spend(sketchbook_id: int, user_id: str):
    """Check if user meets minimum spend requirement."""
    try:
        result = await sketchbook.check_spend_eligibility(sketchbook_id, user_id)
        return result
    except Exception as exc:
        logger.error(f"Failed to check spend eligibility: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/sketchbook/posts/{post_id}/vote")
async def vote_poll(post_id: int, payload: dict):
    """Vote in a poll."""
    try:
        success = await sketchbook.vote_in_poll(
            post_id=post_id,
            user_id=payload["user_id"],
            option_id=payload["option_id"]
        )
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to record vote")
        
        # Return updated poll results
        results = await sketchbook.get_poll_results(post_id)
        return results
    except Exception as exc:
        logger.error(f"Failed to vote in poll {post_id}: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/sketchbook/posts/{post_id}/poll")
async def get_poll(post_id: int):
    """Get poll results."""
    try:
        results = await sketchbook.get_poll_results(post_id)
        if not results:
            raise HTTPException(status_code=404, detail="Poll not found")
        return results
    except Exception as exc:
        logger.error(f"Failed to get poll results: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/sketchbook/posts/{post_id}/react")
async def react_to_post(post_id: int, payload: dict):
    """Add a reaction to a post."""
    try:
        await sketchbook.add_reaction(
            post_id=post_id,
            user_id=payload["user_id"],
            reaction_type=payload.get("reaction_type", "like")
        )
        return {"success": True}
    except Exception as exc:
        logger.error(f"Failed to react to post {post_id}: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.delete("/sketchbook/posts/{post_id}/react")
async def unreact_to_post(post_id: int, user_id: str, reaction_type: str = "like"):
    """Remove a reaction from a post."""
    try:
        success = await sketchbook.remove_reaction(post_id, user_id, reaction_type)
        return {"success": success}
    except Exception as exc:
        logger.error(f"Failed to remove reaction: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/community/sketchbook-feed")
async def get_community_sketchbook_feed(user_id: str, limit: int = 20):
    """Get aggregated sketchbook posts for community feed."""
    try:
        posts = await sketchbook.get_community_feed_posts(user_id, limit)
        return {"posts": posts}
    except Exception as exc:
        logger.error(f"Failed to get community feed: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/health")
async def health():
    """Health check endpoint for load balancers."""
    return {
        "status": "ok",
        "service": "find-this-fit",
        "version": "1.0.0"
    }


@app.get("/metrics")
async def metrics():
    """
    Basic metrics endpoint.
    In production: integrate Prometheus or DataDog.
    """
    # Get DB pool stats
    pool = db._pool
    if pool:
        pool_stats = {
            "pool_size": pool.get_size(),
            "pool_free": pool.get_idle_size(),
        }
    else:
        pool_stats = {"error": "pool_not_initialized"}
    
    return {
        "database": pool_stats,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "backend.app:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
