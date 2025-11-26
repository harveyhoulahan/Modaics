"""
Add category, color, and brand columns to Modaics database.
Parse from titles using the same logic as export_createml_data.py
"""
import asyncio
import asyncpg
from collections import defaultdict

async def add_and_populate_metadata():
    """Add metadata columns and populate from titles"""
    
    print("🔗 Connecting to Modaics database...")
    conn = await asyncpg.connect(
        host='localhost',
        port=5433,
        user='postgres',
        password='postgres',
        database='modaics'
    )
    
    # Add columns if they don't exist
    print("\n📊 Adding metadata columns...")
    await conn.execute("""
        ALTER TABLE fashion_items 
        ADD COLUMN IF NOT EXISTS category VARCHAR(50),
        ADD COLUMN IF NOT EXISTS color VARCHAR(50),
        ADD COLUMN IF NOT EXISTS detected_brand VARCHAR(100)
    """)
    print("✅ Columns added")
    
    # Get all items
    print("\n📦 Fetching items...")
    items = await conn.fetch("SELECT id, title FROM fashion_items WHERE title IS NOT NULL")
    print(f"   Found {len(items):,} items with titles")
    
    # Statistics
    stats = {
        'category': defaultdict(int),
        'color': defaultdict(int),
        'brand': defaultdict(int),
        'updated': 0
    }
    
    print("\n🔄 Parsing titles and updating...")
    
    for idx, item in enumerate(items, 1):
        title_lower = item['title'].lower()
        
        # === CATEGORY CLASSIFICATION ===
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
        color = None
        color_keywords = {
            'black': ['black'],
            'white': ['white', 'cream', 'ivory', 'off-white'],
            'gray': ['gray', 'grey', 'charcoal', 'slate'],
            'navy': ['navy'],
            'blue': ['blue'],
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
        
        # Update item
        await conn.execute("""
            UPDATE fashion_items
            SET category = $1, color = $2, detected_brand = $3
            WHERE id = $4
        """, category, color, brand, item['id'])
        
        stats['category'][category] += 1
        stats['color'][color] += 1
        stats['brand'][brand] += 1
        stats['updated'] += 1
        
        if idx % 1000 == 0:
            progress = (idx / len(items)) * 100
            print(f"   ⏳ Progress: {idx:,}/{len(items):,} ({progress:.1f}%)")
    
    await conn.close()
    
    # Print statistics
    print("\n" + "="*60)
    print("✅ UPDATE COMPLETE!")
    print("="*60)
    print(f"\n📊 Updated {stats['updated']:,} items")
    
    print(f"\n👕 Category Distribution:")
    for cat, count in sorted(stats['category'].items(), key=lambda x: x[1], reverse=True):
        pct = (count / stats['updated']) * 100
        print(f"   {cat:15} {count:6,} ({pct:5.1f}%)")
    
    print(f"\n🎨 Color Distribution:")
    for col, count in sorted(stats['color'].items(), key=lambda x: x[1], reverse=True):
        pct = (count / stats['updated']) * 100
        print(f"   {col:15} {count:6,} ({pct:5.1f}%)")
    
    print(f"\n🏷️  Brand Distribution (top 20):")
    for brd, count in sorted(stats['brand'].items(), key=lambda x: x[1], reverse=True)[:20]:
        pct = (count / stats['updated']) * 100
        print(f"   {brd:20} {count:6,} ({pct:5.1f}%)")
    
    print("\n✅ Now you can re-export training data with:")
    print("   python3 export_createml_data.py")
    print("\n📊 Expected improvements:")
    unknown_pct = (stats['color']['unknown'] / stats['updated']) * 100
    other_pct = (stats['category']['other'] / stats['updated']) * 100
    print(f"   - 'unknown' colors: {unknown_pct:.1f}% (was 63%)")
    print(f"   - 'other' categories: {other_pct:.1f}% (was 28%)")

if __name__ == "__main__":
    asyncio.run(add_and_populate_metadata())
