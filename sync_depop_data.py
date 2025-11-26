"""
Sync Depop items from Find This Fit database to Modaics database.
Only migrates items that don't already exist.
"""
import asyncio
import asyncpg
from datetime import datetime

# Source: Find This Fit database
SOURCE_DB = {
    'host': 'localhost',
    'port': 5432,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'find_this_fit'
}

# Target: Modaics database
TARGET_DB = {
    'host': 'localhost',
    'port': 5433,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'modaics'
}

async def sync_depop_items():
    """Sync Depop items from Find This Fit to Modaics"""
    
    print("🔗 Connecting to databases...")
    
    # Connect to both databases
    source_conn = await asyncpg.connect(**SOURCE_DB)
    target_conn = await asyncpg.connect(**TARGET_DB)
    
    # Get existing items in Modaics (by URL to avoid duplicates)
    print("📊 Checking existing items in Modaics...")
    existing_urls = await target_conn.fetch("SELECT item_url FROM fashion_items")
    existing_url_set = {row['item_url'] for row in existing_urls if row['item_url']}
    print(f"   Found {len(existing_url_set):,} existing items")
    
    # Get all Depop items from Find This Fit
    print("📦 Fetching Depop items from Find This Fit...")
    depop_items = await source_conn.fetch("""
        SELECT id, source, external_id, title, description, price, currency,
               url, image_url, seller_name, size, brand, category, condition
        FROM fashion_items
        WHERE source = 'depop'
        ORDER BY id
    """)
    print(f"   Found {len(depop_items):,} Depop items")
    
    # Filter out items that already exist
    new_items = [item for item in depop_items if item['url'] not in existing_url_set]
    print(f"   {len(new_items):,} new items to migrate")
    
    if len(new_items) == 0:
        print("✅ No new items to migrate!")
        await source_conn.close()
        await target_conn.close()
        return
    
    # Insert new items
    print(f"\n🚀 Migrating {len(new_items):,} items...")
    inserted = 0
    failed = 0
    
    for idx, item in enumerate(new_items, 1):
        try:
            await target_conn.execute("""
                INSERT INTO fashion_items 
                (title, brand, description, price, image_url, item_url, 
                 platform, size, condition, location, seller_username)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            """,
                item['title'] or 'Unknown Item',
                item['brand'] or 'Unknown',
                item['description'] or '',
                item['price'] or 0,
                item['image_url'],
                item['url'],
                'depop',
                item['size'] or 'M',
                item['condition'] or 'Good',
                'Depop',
                item['seller_name'] or 'depop_user'
            )
            inserted += 1
            
            if idx % 100 == 0:
                progress = (idx / len(new_items)) * 100
                print(f"   ⏳ Progress: {idx:,}/{len(new_items):,} ({progress:.1f}%)")
                
        except Exception as e:
            failed += 1
            if idx % 1000 == 0:
                print(f"   ⚠️  Error at {idx}: {str(e)[:50]}")
            continue
    
    await source_conn.close()
    await target_conn.close()
    
    # Summary
    print("\n" + "="*60)
    print("✅ MIGRATION COMPLETE!")
    print("="*60)
    print(f"Total Depop items in Find This Fit: {len(depop_items):,}")
    print(f"Already existed in Modaics: {len(depop_items) - len(new_items):,}")
    print(f"New items migrated: {inserted:,}")
    print(f"Failed: {failed:,}")
    print(f"\n📊 New total in Modaics: ~{len(existing_url_set) + inserted:,} items")

if __name__ == "__main__":
    asyncio.run(sync_depop_items())
