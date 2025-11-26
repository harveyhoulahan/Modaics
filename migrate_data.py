#!/usr/bin/env python3
"""
Migrate fashion items from FindThisFit database to Modaics database.
Maps incompatible schemas and preserves embeddings.
"""

import asyncpg
import asyncio
from typing import List, Dict, Any

FINDTHISFIT_DB = "postgresql://postgres:postgres@localhost:5432/find_this_fit"
MODAICS_DB = "postgresql://postgres:postgres@localhost:5433/modaics"

BATCH_SIZE = 1000


async def migrate_fashion_items():
    """Migrate all fashion items with schema mapping."""
    
    # Connect to both databases
    source_conn = await asyncpg.connect(FINDTHISFIT_DB)
    target_conn = await asyncpg.connect(MODAICS_DB)
    
    try:
        # Get total count
        total = await source_conn.fetchval("SELECT COUNT(*) FROM fashion_items")
        print(f"📊 Total items to migrate: {total:,}")
        
        # Fetch all items in batches
        offset = 0
        migrated = 0
        
        while offset < total:
            # Fetch batch from source
            items = await source_conn.fetch(f"""
                SELECT 
                    id, source, external_id, title, description,
                    price, currency, url, image_url, seller_name,
                    size, brand, category, condition, embedding,
                    created_at, updated_at
                FROM fashion_items
                ORDER BY id
                LIMIT {BATCH_SIZE} OFFSET {offset}
            """)
            
            if not items:
                break
                
            # Map and insert into target
            for item in items:
                # Map FindThisFit schema to Modaics schema
                try:
                    await target_conn.execute("""
                        INSERT INTO fashion_items (
                            title, price, image_url, item_url, platform,
                            brand, size, condition, description, 
                            seller_username, embedding
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                    """,
                        item['title'] or 'Untitled',
                        item['price'],
                        item['image_url'],
                        item['url'] or f"https://{item['source']}.com/item/{item['external_id']}",
                        item['source'],  # source -> platform
                        item['brand'],
                        item['size'],
                        item['condition'],
                        item['description'],
                        item['seller_name'],  # seller_name -> seller_username
                        item['embedding']
                    )
                    migrated += 1
                except Exception as e:
                    print(f"⚠️  Error migrating item {item['id']}: {e}")
                    continue
            
            offset += BATCH_SIZE
            print(f"✅ Migrated {migrated:,} / {total:,} items ({100 * migrated / total:.1f}%)")
        
        # Verify migration
        final_count = await target_conn.fetchval("SELECT COUNT(*) FROM fashion_items")
        embedded_count = await target_conn.fetchval(
            "SELECT COUNT(*) FROM fashion_items WHERE embedding IS NOT NULL"
        )
        
        print(f"\n🎉 Migration complete!")
        print(f"   Total items: {final_count:,}")
        print(f"   With embeddings: {embedded_count:,}")
        print(f"   Success rate: {100 * final_count / total:.1f}%")
        
    finally:
        await source_conn.close()
        await target_conn.close()


if __name__ == "__main__":
    asyncio.run(migrate_fashion_items())
