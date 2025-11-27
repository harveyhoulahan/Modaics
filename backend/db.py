"""
Production-grade async database layer with connection pooling.
Uses asyncpg for high-performance async PostgreSQL access.
"""
import asyncpg
from contextlib import asynccontextmanager
from typing import List, Dict, Any, Optional

try:
    from .config import DATABASE_URL
except ImportError:
    from config import DATABASE_URL

# Global connection pool
_pool: Optional[asyncpg.Pool] = None


async def init_pool(min_size: int = 2, max_size: int = 10):
    """Initialize the connection pool at app startup."""
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(
            DATABASE_URL,
            min_size=min_size,
            max_size=max_size,
            command_timeout=60,
        )


async def close_pool():
    """Close the connection pool at app shutdown."""
    global _pool
    if _pool:
        await _pool.close()
        _pool = None


@asynccontextmanager
async def get_connection():
    """Get a connection from the pool."""
    if _pool is None:
        raise RuntimeError("Database pool not initialized. Call init_pool() first.")
    async with _pool.acquire() as conn:
        yield conn


async def fetch_all(query: str, params: Optional[List[Any]] = None) -> List[Dict[str, Any]]:
    """Execute a query and return all rows as dicts."""
    async with get_connection() as conn:
        rows = await conn.fetch(query, *(params or []))
        return [dict(row) for row in rows]


async def fetch_one(query: str, params: Optional[List[Any]] = None) -> Optional[Dict[str, Any]]:
    """Execute a query and return one row as dict."""
    async with get_connection() as conn:
        row = await conn.fetchrow(query, *(params or []))
        return dict(row) if row else None


async def execute(query: str, params: Optional[List[Any]] = None) -> str:
    """Execute a query without returning results."""
    async with get_connection() as conn:
        return await conn.execute(query, *(params or []))


async def insert_item(item_data: Dict[str, Any]) -> int:
    """
    Insert a new item with CLIP embeddings into the database.
    
    Args:
        item_data: Dictionary containing:
            - title: str
            - description: str
            - price: float
            - brand: str (optional)
            - category: str (optional)
            - size: str (optional)
            - condition: str (optional)
            - owner_id: str (optional)
            - source: str (default: "modaics")
            - image_url: str (optional)
            - embedding: List[float] (768-dim CLIP embedding)
    
    Returns:
        int: ID of the newly inserted item
    """
    query = """
        INSERT INTO fashion_items (
            title,
            description,
            price,
            image_url,
            item_url,
            platform,
            brand,
            size,
            condition,
            location,
            seller_username,
            embedding
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
        )
        RETURNING id
    """
    
    # Use owner_id as seller_username for Modaics items
    owner_id = item_data.get('owner_id', 'modaics_user')
    
    params = [
        item_data.get("title"),
        item_data.get("description"),
        item_data.get("price"),
        item_data.get("image_url", ""),
        "",  # item_url - not needed for Modaics items
        "modaics",  # platform - using custom value, not constrained to depop/grailed/vinted
        item_data.get("brand", ""),
        item_data.get("size", ""),
        item_data.get("condition", ""),
        "",  # location - can be added later
        owner_id,  # seller_username
        item_data.get("embedding"),
    ]
    
    async with get_connection() as conn:
        row = await conn.fetchrow(query, *params)
        return row["id"]


# Legacy sync functions for ingestion scripts
def get_connection_sync():
    """Synchronous connection for scraping/embedding scripts."""
    import psycopg2
    import psycopg2.extras
    conn = psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)
    conn.autocommit = True
    return conn


def fetch_all_sync(query, params=None):
    with get_connection_sync() as conn:
        with conn.cursor() as cur:
            cur.execute(query, params or [])
            return cur.fetchall()


def execute_sync(query, params=None):
    with get_connection_sync() as conn:
        with conn.cursor() as cur:
            cur.execute(query, params or [])
