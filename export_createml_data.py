"""
Export training data from Modaics database for Create ML training.
Organizes ~39k images by category, color, and brand.
"""
import asyncio
import asyncpg
import aiohttp
import os
from pathlib import Path
from collections import defaultdict
import json

# Configuration
MODAICS_DB_HOST = 'localhost'
MODAICS_DB_PORT = 5433  # Modaics database
MODAICS_DB_NAME = 'modaics'

OUTPUT_DIR = Path('createml_training_data')

async def export_for_createml():
    """Export data organized for Create ML Image Classifiers"""
    
    print("🔗 Connecting to Modaics database...")
    try:
        conn = await asyncpg.connect(
            host=MODAICS_DB_HOST,
            port=MODAICS_DB_PORT,
            user='postgres',
            password='postgres',
            database=MODAICS_DB_NAME
        )
    except Exception as e:
        print(f"❌ Could not connect to Modaics database: {e}")
        print("⚠️  Make sure the database is running")
        return
    
    # Get total count
    total_count = await conn.fetchval("SELECT COUNT(*) FROM fashion_items WHERE image_url IS NOT NULL")
    print(f"📊 Found {total_count:,} items with images")
    
    # Query all items with images
    items = await conn.fetch("""
        SELECT id, title, description, price, item_url, image_url, platform
        FROM fashion_items
        WHERE image_url IS NOT NULL
        ORDER BY id
    """)
    
    print(f"\n📦 Preparing to export {len(items):,} items...")
    
    # Statistics
    stats = {
        'category': defaultdict(int),
        'color': defaultdict(int),
        'brand': defaultdict(int),
        'platform': defaultdict(int),
        'downloaded': 0,
        'failed': 0
    }
    
    # Create ML folders
    category_dir = OUTPUT_DIR / 'category_classifier'
    color_dir = OUTPUT_DIR / 'color_classifier'
    brand_dir = OUTPUT_DIR / 'brand_classifier'
    
    # Download images with progress
    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as session:
        for idx, item in enumerate(items, 1):
            try:
                title_lower = item['title'].lower()
                
                # === CATEGORY CLASSIFICATION ===
                # Be more specific with categories for better training
                category = None
                
                # Jackets & Outerwear (most specific first)
                if any(w in title_lower for w in ['jacket', 'coat', 'blazer', 'parka', 'windbreaker', 'anorak']):
                    category = 'jacket'
                elif any(w in title_lower for w in ['hoodie', 'sweatshirt']):
                    category = 'hoodie'
                elif any(w in title_lower for w in ['sweater', 'jumper', 'cardigan', 'knit']):
                    category = 'sweater'
                
                # Tops
                elif 'polo' in title_lower:
                    category = 'polo'
                elif any(w in title_lower for w in ['t-shirt', 'tee', 'tshirt']):
                    category = 'tshirt'
                elif any(w in title_lower for w in ['shirt', 'blouse']):
                    category = 'shirt'
                elif any(w in title_lower for w in ['tank', 'vest']):
                    category = 'tank'
                elif any(w in title_lower for w in ['top', 'crop']):
                    category = 'top'
                
                # Bottoms
                elif 'jeans' in title_lower or 'denim' in title_lower:
                    category = 'jeans'
                elif any(w in title_lower for w in ['shorts', 'short']):
                    category = 'shorts'
                elif any(w in title_lower for w in ['pants', 'trouser', 'chino', 'jogger', 'sweatpant']):
                    category = 'pants'
                elif 'skirt' in title_lower:
                    category = 'skirt'
                
                # Dresses
                elif 'dress' in title_lower or 'gown' in title_lower:
                    category = 'dress'
                
                # Shoes
                elif any(w in title_lower for w in ['sneaker', 'trainer', 'runner']):
                    category = 'sneakers'
                elif any(w in title_lower for w in ['boot', 'boots']):
                    category = 'boots'
                elif any(w in title_lower for w in ['shoe', 'loafer', 'oxford', 'derby']):
                    category = 'shoes'
                
                # Accessories
                elif any(w in title_lower for w in ['bag', 'backpack', 'purse', 'tote']):
                    category = 'bag'
                elif any(w in title_lower for w in ['hat', 'cap', 'beanie']):
                    category = 'hat'
                else:
                    category = 'other'
                
                # === COLOR CLASSIFICATION ===
                # Extract color from title
                color = None
                color_keywords = {
                    'black': ['black'],
                    'white': ['white', 'cream', 'ivory', 'off-white'],
                    'gray': ['gray', 'grey', 'charcoal', 'slate'],
                    'navy': ['navy'],
                    'blue': ['blue'],
                    'light_blue': ['light blue', 'sky blue', 'baby blue', 'powder blue'],
                    'red': ['red', 'burgundy', 'maroon'],
                    'pink': ['pink', 'rose'],
                    'green': ['green', 'olive', 'khaki', 'sage', 'forest'],
                    'yellow': ['yellow', 'mustard', 'gold'],
                    'orange': ['orange', 'rust', 'copper'],
                    'brown': ['brown', 'tan', 'beige', 'camel', 'taupe'],
                    'purple': ['purple', 'lavender', 'violet'],
                    'multicolor': ['multi', 'print', 'pattern', 'floral', 'stripe', 'plaid', 'camo']
                }
                
                for color_name, keywords in color_keywords.items():
                    if any(kw in title_lower for kw in keywords):
                        color = color_name
                        break
                
                if not color:
                    color = 'unknown'
                
                # === BRAND CLASSIFICATION ===
                # Extract brand from title
                brand_keywords = [
                    'nike', 'adidas', 'supreme', 'palace', 'stussy', 'carhartt',
                    'dickies', 'levis', "levi's", 'wrangler', 'lee',
                    'ralph lauren', 'polo', 'tommy hilfiger', 'tommy',
                    'gap', 'old navy', 'h&m', 'zara', 'uniqlo',
                    'north face', 'patagonia', 'columbia', 
                    'gucci', 'prada', 'louis vuitton', 'balenciaga', 'versace',
                    'ami', 'ami paris', 'stone island', 'cp company',
                    'vans', 'converse', 'new balance', 'reebok', 'puma'
                ]
                
                brand = 'other'
                for brand_kw in brand_keywords:
                    if brand_kw.lower() in title_lower:
                        brand = brand_kw.replace(' ', '_').replace("'", "")
                        break
                
                # Download image
                try:
                    async with session.get(item['image_url']) as resp:
                        if resp.status == 200:
                            image_data = await resp.read()
                            
                            # Save to category folder
                            if category:
                                cat_path = category_dir / category
                                cat_path.mkdir(parents=True, exist_ok=True)
                                with open(cat_path / f"{item['id']}.jpg", 'wb') as f:
                                    f.write(image_data)
                                stats['category'][category] += 1
                            
                            # Save to color folder
                            if color:
                                col_path = color_dir / color
                                col_path.mkdir(parents=True, exist_ok=True)
                                with open(col_path / f"{item['id']}.jpg", 'wb') as f:
                                    f.write(image_data)
                                stats['color'][color] += 1
                            
                            # Save to brand folder (only if brand detected)
                            if brand != 'other':
                                brd_path = brand_dir / brand
                                brd_path.mkdir(parents=True, exist_ok=True)
                                with open(brd_path / f"{item['id']}.jpg", 'wb') as f:
                                    f.write(image_data)
                                stats['brand'][brand] += 1
                            
                            stats['downloaded'] += 1
                            stats['platform'][item['platform']] += 1
                            
                            # Progress update
                            if idx % 100 == 0:
                                progress = (idx / len(items)) * 100
                                print(f"⏳ Progress: {idx:,}/{len(items):,} ({progress:.1f}%)")
                        else:
                            stats['failed'] += 1
                            
                except Exception as e:
                    stats['failed'] += 1
                    if idx % 1000 == 0:  # Only print occasional errors
                        print(f"⚠️  Error downloading {item['id']}: {str(e)[:50]}")
                    continue
                    
            except Exception as e:
                print(f"❌ Error processing item {item['id']}: {e}")
                stats['failed'] += 1
                continue
    
    await conn.close()
    
    # Print statistics
    print("\n" + "="*60)
    print("✅ EXPORT COMPLETE!")
    print("="*60)
    print(f"\n📊 Summary:")
    print(f"   Total processed: {len(items):,}")
    print(f"   Successfully downloaded: {stats['downloaded']:,}")
    print(f"   Failed: {stats['failed']:,}")
    
    print(f"\n📦 By Platform:")
    for platform, count in sorted(stats['platform'].items(), key=lambda x: x[1], reverse=True):
        print(f"   {platform}: {count:,}")
    
    print(f"\n👕 Category Distribution (top 15):")
    for cat, count in sorted(stats['category'].items(), key=lambda x: x[1], reverse=True)[:15]:
        print(f"   {cat}: {count:,}")
    
    print(f"\n🎨 Color Distribution:")
    for col, count in sorted(stats['color'].items(), key=lambda x: x[1], reverse=True):
        print(f"   {col}: {count:,}")
    
    print(f"\n🏷️  Brand Distribution (top 20):")
    for brd, count in sorted(stats['brand'].items(), key=lambda x: x[1], reverse=True)[:20]:
        print(f"   {brd}: {count:,}")
    
    # Save metadata
    metadata = {
        'total_items': len(items),
        'downloaded': stats['downloaded'],
        'failed': stats['failed'],
        'categories': dict(stats['category']),
        'colors': dict(stats['color']),
        'brands': dict(stats['brand']),
        'platforms': dict(stats['platform'])
    }
    
    with open(OUTPUT_DIR / 'export_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    print(f"\n📁 Data exported to: {OUTPUT_DIR.absolute()}")
    print("\n🚀 Next Steps:")
    print("1. Open Create ML app on macOS")
    print("2. Create New Image Classifier project")
    print("3. Point to folders:")
    print(f"   - Category: {(category_dir).absolute()}")
    print(f"   - Color: {(color_dir).absolute()}")
    print(f"   - Brand: {(brand_dir).absolute()}")
    print("4. Train models (will take 30-60 minutes each)")
    print("5. Export .mlmodel files to iOS project")

if __name__ == "__main__":
    asyncio.run(export_for_createml())
