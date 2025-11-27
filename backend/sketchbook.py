"""
Sketchbook API routes for Modaics backend.
Handles brand workspaces, posts, membership, and polls.
"""
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime

try:
    from . import db
except ImportError:
    import db

logger = logging.getLogger(__name__)


# ============================================================================
# SKETCHBOOK CRUD
# ============================================================================

async def get_sketchbook_by_brand(brand_id: str) -> Optional[Dict[str, Any]]:
    """Get a brand's sketchbook (creates one if doesn't exist)."""
    query = """
        SELECT id, brand_id, title, description, access_policy, membership_rule,
               min_spend_amount, min_spend_window_months, members_count, posts_count,
               created_at, updated_at
        FROM sketchbooks
        WHERE brand_id = $1
    """
    
    async with db._pool.acquire() as conn:
        row = await conn.fetchrow(query, brand_id)
        
        if row:
            return dict(row)
        
        # Create default sketchbook if doesn't exist
        logger.info(f"Creating default sketchbook for brand {brand_id}")
        insert_query = """
            INSERT INTO sketchbooks (brand_id, title, description, access_policy, membership_rule)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, brand_id, title, description, access_policy, membership_rule,
                      min_spend_amount, min_spend_window_months, members_count, posts_count,
                      created_at, updated_at
        """
        
        new_row = await conn.fetchrow(
            insert_query,
            brand_id,
            "Studio Updates",  # Default title
            "Welcome to our creative workspace",  # Default description
            "publicRead",  # Default to public
            "free"  # Default to free access
        )
        
        return dict(new_row) if new_row else None


async def update_sketchbook_settings(
    sketchbook_id: int,
    title: Optional[str] = None,
    description: Optional[str] = None,
    access_policy: Optional[str] = None,
    membership_rule: Optional[str] = None,
    min_spend_amount: Optional[float] = None,
    min_spend_window_months: Optional[int] = None
) -> Optional[Dict[str, Any]]:
    """Update sketchbook settings."""
    updates = []
    params = []
    param_idx = 1
    
    if title is not None:
        updates.append(f"title = ${param_idx}")
        params.append(title)
        param_idx += 1
    
    if description is not None:
        updates.append(f"description = ${param_idx}")
        params.append(description)
        param_idx += 1
    
    if access_policy is not None:
        updates.append(f"access_policy = ${param_idx}")
        params.append(access_policy)
        param_idx += 1
    
    if membership_rule is not None:
        updates.append(f"membership_rule = ${param_idx}")
        params.append(membership_rule)
        param_idx += 1
    
    if min_spend_amount is not None:
        updates.append(f"min_spend_amount = ${param_idx}")
        params.append(min_spend_amount)
        param_idx += 1
    
    if min_spend_window_months is not None:
        updates.append(f"min_spend_window_months = ${param_idx}")
        params.append(min_spend_window_months)
        param_idx += 1
    
    if not updates:
        return None
    
    query = f"""
        UPDATE sketchbooks
        SET {', '.join(updates)}, updated_at = NOW()
        WHERE id = ${param_idx}
        RETURNING id, brand_id, title, description, access_policy, membership_rule,
                  min_spend_amount, min_spend_window_months, members_count, posts_count,
                  created_at, updated_at
    """
    params.append(sketchbook_id)
    
    async with db._pool.acquire() as conn:
        row = await conn.fetchrow(query, *params)
        return dict(row) if row else None


# ============================================================================
# POSTS CRUD
# ============================================================================

async def get_sketchbook_posts(
    sketchbook_id: int,
    user_id: Optional[str] = None,
    limit: int = 50
) -> List[Dict[str, Any]]:
    """Get posts from a sketchbook, filtered by user access."""
    # Check if user has access to members-only content
    has_membership = False
    if user_id:
        membership_query = """
            SELECT status FROM sketchbook_memberships
            WHERE sketchbook_id = $1 AND user_id = $2 AND status = 'active'
        """
        async with db._pool.acquire() as conn:
            membership = await conn.fetchrow(membership_query, sketchbook_id, user_id)
            has_membership = membership is not None
    
    # Build query based on access
    if has_membership:
        # Show all posts
        visibility_filter = ""
    else:
        # Show only public posts
        visibility_filter = "AND visibility = 'public'"
    
    query = f"""
        SELECT p.id, p.sketchbook_id, p.author_user_id, p.post_type, p.title, p.body,
               p.media, p.tags, p.visibility, p.poll_question, p.poll_options, p.poll_closes_at,
               p.event_id, p.event_highlight, p.views_count, p.reactions_count, p.comments_count,
               p.created_at, p.updated_at,
               u.username as author_username, u.display_name as author_display_name
        FROM sketchbook_posts p
        LEFT JOIN users u ON p.author_user_id = u.id
        WHERE p.sketchbook_id = $1 {visibility_filter}
        ORDER BY p.created_at DESC
        LIMIT $2
    """
    
    async with db._pool.acquire() as conn:
        rows = await conn.fetch(query, sketchbook_id, limit)
        return [dict(row) for row in rows]


async def create_sketchbook_post(
    sketchbook_id: int,
    author_user_id: str,
    post_type: str,
    title: str,
    body: Optional[str] = None,
    media: Optional[List[Dict]] = None,
    tags: Optional[List[str]] = None,
    visibility: str = "public",
    poll_question: Optional[str] = None,
    poll_options: Optional[List[Dict]] = None,
    poll_closes_at: Optional[datetime] = None,
    event_id: Optional[int] = None,
    event_highlight: Optional[str] = None
) -> Optional[Dict[str, Any]]:
    """Create a new sketchbook post."""
    import json
    
    query = """
        INSERT INTO sketchbook_posts (
            sketchbook_id, author_user_id, post_type, title, body, media, tags,
            visibility, poll_question, poll_options, poll_closes_at,
            event_id, event_highlight
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING id, sketchbook_id, author_user_id, post_type, title, body,
                  media, tags, visibility, poll_question, poll_options, poll_closes_at,
                  event_id, event_highlight, views_count, reactions_count, comments_count,
                  created_at, updated_at
    """
    
    async with db._pool.acquire() as conn:
        row = await conn.fetchrow(
            query,
            sketchbook_id,
            author_user_id,
            post_type,
            title,
            body,
            json.dumps(media) if media else '[]',
            tags,
            visibility,
            poll_question,
            json.dumps(poll_options) if poll_options else None,
            poll_closes_at,
            event_id,
            event_highlight
        )
        
        # Increment posts count
        await conn.execute(
            "UPDATE sketchbooks SET posts_count = posts_count + 1 WHERE id = $1",
            sketchbook_id
        )
        
        return dict(row) if row else None


async def delete_sketchbook_post(post_id: int, author_user_id: str) -> bool:
    """Delete a post (only by author)."""
    query = """
        DELETE FROM sketchbook_posts
        WHERE id = $1 AND author_user_id = $2
        RETURNING sketchbook_id
    """
    
    async with db._pool.acquire() as conn:
        row = await conn.fetchrow(query, post_id, author_user_id)
        
        if row:
            # Decrement posts count
            await conn.execute(
                "UPDATE sketchbooks SET posts_count = posts_count - 1 WHERE id = $1",
                row['sketchbook_id']
            )
            return True
        
        return False


# ============================================================================
# MEMBERSHIP
# ============================================================================

async def check_membership(sketchbook_id: int, user_id: str) -> Optional[Dict[str, Any]]:
    """Check if user has active membership."""
    query = """
        SELECT id, sketchbook_id, user_id, status, join_source, joined_at
        FROM sketchbook_memberships
        WHERE sketchbook_id = $1 AND user_id = $2
    """
    
    async with db._pool.acquire() as conn:
        row = await conn.fetchrow(query, sketchbook_id, user_id)
        return dict(row) if row else None


async def request_membership(
    sketchbook_id: int,
    user_id: str,
    join_source: str = "requestApproved"
) -> Optional[Dict[str, Any]]:
    """Request or grant membership to a sketchbook."""
    query = """
        INSERT INTO sketchbook_memberships (sketchbook_id, user_id, status, join_source)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (sketchbook_id, user_id)
        DO UPDATE SET status = $3, joined_at = NOW()
        RETURNING id, sketchbook_id, user_id, status, join_source, joined_at
    """
    
    async with db._pool.acquire() as conn:
        row = await conn.fetchrow(query, sketchbook_id, user_id, "active", join_source)
        
        if row:
            # Increment members count
            await conn.execute(
                "UPDATE sketchbooks SET members_count = members_count + 1 WHERE id = $1",
                sketchbook_id
            )
        
        return dict(row) if row else None


async def check_spend_eligibility(sketchbook_id: int, user_id: str) -> Dict[str, Any]:
    """Check if user meets minimum spend requirement."""
    # Get sketchbook spend requirements
    sketchbook_query = """
        SELECT min_spend_amount, min_spend_window_months
        FROM sketchbooks
        WHERE id = $1
    """
    
    async with db._pool.acquire() as conn:
        sketchbook = await conn.fetchrow(sketchbook_query, sketchbook_id)
        
        if not sketchbook or not sketchbook['min_spend_amount']:
            return {"eligible": False, "reason": "No spend requirement"}
        
        # Calculate user's spend with brand in the window
        # Note: This assumes transactions table links to brand via seller_id
        spend_query = """
            SELECT COALESCE(SUM(price), 0) as total_spend
            FROM transactions
            WHERE buyer_id = $1
              AND seller_id = (SELECT brand_id FROM sketchbooks WHERE id = $2)
              AND status = 'completed'
              AND completed_at >= NOW() - INTERVAL '1 month' * $3
        """
        
        spend_row = await conn.fetchrow(
            spend_query,
            user_id,
            sketchbook_id,
            sketchbook['min_spend_window_months'] or 6
        )
        
        total_spend = float(spend_row['total_spend']) if spend_row else 0.0
        required = float(sketchbook['min_spend_amount'])
        
        return {
            "eligible": total_spend >= required,
            "total_spend": total_spend,
            "required_spend": required,
            "window_months": sketchbook['min_spend_window_months']
        }


# ============================================================================
# POLLS
# ============================================================================

async def vote_in_poll(post_id: int, user_id: str, option_id: str) -> bool:
    """Vote in a poll."""
    import json
    
    async with db._pool.acquire() as conn:
        # Insert or update vote
        vote_query = """
            INSERT INTO sketchbook_poll_votes (post_id, user_id, option_id)
            VALUES ($1, $2, $3)
            ON CONFLICT (post_id, user_id)
            DO UPDATE SET option_id = $3, voted_at = NOW()
        """
        
        await conn.execute(vote_query, post_id, user_id, option_id)
        
        # Recalculate vote counts for the poll
        # Get all votes for this post
        votes_query = """
            SELECT option_id, COUNT(*) as vote_count
            FROM sketchbook_poll_votes
            WHERE post_id = $1
            GROUP BY option_id
        """
        
        votes = await conn.fetch(votes_query, post_id)
        vote_counts = {row['option_id']: row['vote_count'] for row in votes}
        
        # Update poll_options with vote counts
        post_query = "SELECT poll_options FROM sketchbook_posts WHERE id = $1"
        post_row = await conn.fetchrow(post_query, post_id)
        
        if post_row and post_row['poll_options']:
            options = json.loads(post_row['poll_options']) if isinstance(post_row['poll_options'], str) else post_row['poll_options']
            
            # Update vote counts
            for option in options:
                option['votes'] = vote_counts.get(option['id'], 0)
            
            # Save back to database
            update_query = """
                UPDATE sketchbook_posts
                SET poll_options = $1
                WHERE id = $2
            """
            await conn.execute(update_query, json.dumps(options), post_id)
        
        return True


async def get_poll_results(post_id: int) -> Optional[Dict[str, Any]]:
    """Get poll results with vote counts."""
    query = """
        SELECT poll_question, poll_options, poll_closes_at
        FROM sketchbook_posts
        WHERE id = $1 AND post_type = 'poll'
    """
    
    async with db._pool.acquire() as conn:
        row = await conn.fetchrow(query, post_id)
        
        if not row:
            return None
        
        # Get user's vote if they voted
        import json
        options = json.loads(row['poll_options']) if isinstance(row['poll_options'], str) else row['poll_options']
        
        return {
            "question": row['poll_question'],
            "options": options,
            "closes_at": row['poll_closes_at'],
            "is_closed": row['poll_closes_at'] and datetime.now() > row['poll_closes_at']
        }


# ============================================================================
# REACTIONS & COMMENTS
# ============================================================================

async def add_reaction(post_id: int, user_id: str, reaction_type: str = "like") -> bool:
    """Add a reaction to a post."""
    query = """
        INSERT INTO sketchbook_reactions (post_id, user_id, reaction_type)
        VALUES ($1, $2, $3)
        ON CONFLICT (post_id, user_id, reaction_type) DO NOTHING
    """
    
    async with db._pool.acquire() as conn:
        await conn.execute(query, post_id, user_id, reaction_type)
        
        # Update reactions count
        await conn.execute(
            "UPDATE sketchbook_posts SET reactions_count = reactions_count + 1 WHERE id = $1",
            post_id
        )
        
        return True


async def remove_reaction(post_id: int, user_id: str, reaction_type: str = "like") -> bool:
    """Remove a reaction from a post."""
    query = """
        DELETE FROM sketchbook_reactions
        WHERE post_id = $1 AND user_id = $2 AND reaction_type = $3
    """
    
    async with db._pool.acquire() as conn:
        result = await conn.execute(query, post_id, user_id, reaction_type)
        
        if result:
            # Update reactions count
            await conn.execute(
                "UPDATE sketchbook_posts SET reactions_count = GREATEST(0, reactions_count - 1) WHERE id = $1",
                post_id
            )
            return True
        
        return False


async def get_community_feed_posts(user_id: str, limit: int = 20) -> List[Dict[str, Any]]:
    """Get sketchbook posts from brands the user follows or has membership with."""
    query = """
        SELECT DISTINCT p.id, p.sketchbook_id, p.author_user_id, p.post_type, p.title, p.body,
               p.media, p.tags, p.visibility, p.poll_question, p.poll_options, p.poll_closes_at,
               p.event_id, p.event_highlight, p.views_count, p.reactions_count, p.comments_count,
               p.created_at, p.updated_at,
               u.username as author_username, u.display_name as author_display_name,
               s.title as sketchbook_title, s.brand_id
        FROM sketchbook_posts p
        LEFT JOIN users u ON p.author_user_id = u.id
        LEFT JOIN sketchbooks s ON p.sketchbook_id = s.id
        WHERE (
            -- User has active membership
            EXISTS (
                SELECT 1 FROM sketchbook_memberships m
                WHERE m.sketchbook_id = p.sketchbook_id
                  AND m.user_id = $1
                  AND m.status = 'active'
            )
            OR
            -- User follows the brand
            EXISTS (
                SELECT 1 FROM user_follows f
                WHERE f.follower_id = $1
                  AND f.following_id = s.brand_id
            )
        )
        AND (
            -- Post is public OR user has membership
            p.visibility = 'public'
            OR
            EXISTS (
                SELECT 1 FROM sketchbook_memberships m
                WHERE m.sketchbook_id = p.sketchbook_id
                  AND m.user_id = $1
                  AND m.status = 'active'
            )
        )
        ORDER BY p.created_at DESC
        LIMIT $2
    """
    
    async with db._pool.acquire() as conn:
        rows = await conn.fetch(query, user_id, limit)
        return [dict(row) for row in rows]
