import asyncio
import asyncpg
import aiohttp
import os
from pathlib import Path

async def export_training_data():
    # Connect to database
    conn = await asyncpg.connect(
        host='localhost',
        port=5433,
        user='postgres',
        password='postgres',
        database='fashiondb'
    )
    
    # Query all items with images
    items = await conn.fetch("""
        SELECT id, title, description, price, url, image_url
        FROM fashion_items
        WHERE image_url IS NOT NULL
        LIMIT 10000
    """)
    
    print(f"Found {len(items)} items to export")
    
    # Download images and organize by category
    async with aiohttp.ClientSession() as session:
        for idx, item in enumerate(items):
            try:
                # Determine category from title
                title_lower = item['title'].lower()
                
                if any(w in title_lower for w in ['shirt', 'tee', 'top', 'polo', 'blouse']):
                    category = 'tops'
                elif any(w in title_lower for w in ['pants', 'jeans', 'shorts', 'trouser']):
                    category = 'bottoms'
                elif any(w in title_lower for w in ['dress', 'gown']):
                    category = 'dresses'
                elif any(w in title_lower for w in ['jacket', 'coat', 'hoodie', 'sweater']):
                    category = 'outerwear'
                elif any(w in title_lower for w in ['shoe', 'sneaker', 'boot']):
                    category = 'shoes'
                else:
                    category = 'accessories'
                
                # Create category directory
                category_dir = Path(f'training_data/category/{category}')
                category_dir.mkdir(parents=True, exist_ok=True)
                
                # Download image
                async with session.get(item['image_url']) as resp:
                    if resp.status == 200:
                        image_data = await resp.read()
                        
                        # Save to category folder
                        image_path = category_dir / f"{item['id']}.jpg"
                        with open(image_path, 'wb') as f:
                            f.write(image_data)
                        
                        if (idx + 1) % 100 == 0:
                            print(f"Exported {idx + 1}/{len(items)} images")
                            
            except Exception as e:
                print(f"Error exporting item {item['id']}: {e}")
                continue
    
    await conn.close()
    print("Export complete!")

if __name__ == "__main__":
    asyncio.run(export_training_data())