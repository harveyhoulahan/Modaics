-- Modaics Database Schema
-- PostgreSQL with pgvector extension for CLIP embeddings

-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Fashion items table (from FindThisFit + Modaics)
-- This will store all scraped items + user-created listings with CLIP embeddings
CREATE TABLE IF NOT EXISTS fashion_items (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    price NUMERIC(10, 2),
    image_url TEXT,
    item_url TEXT,  -- Can be empty for Modaics user listings
    platform VARCHAR(20) CHECK (platform IN ('depop', 'grailed', 'vinted', 'modaics')),
    brand VARCHAR(100),
    size VARCHAR(20),
    condition VARCHAR(50),
    description TEXT,
    location VARCHAR(100),
    seller_username VARCHAR(100),
    
    -- CLIP embedding (768-dimensional for clip-ViT-B-32)
    embedding vector(768),
    
    -- Modaics-specific fields
    sustainability_score INTEGER CHECK (sustainability_score >= 0 AND sustainability_score <= 100),
    is_verified_sustainable BOOLEAN DEFAULT FALSE,
    material VARCHAR(100),
    certifications TEXT[],
    
    -- Metadata
    scraped_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create HNSW index for fast vector similarity search
-- This enables <=> operator for cosine similarity
CREATE INDEX IF NOT EXISTS idx_fashion_items_embedding 
ON fashion_items 
USING hnsw (embedding vector_cosine_ops);

-- Indexes for filtering
CREATE INDEX IF NOT EXISTS idx_fashion_items_platform ON fashion_items(platform);
CREATE INDEX IF NOT EXISTS idx_fashion_items_brand ON fashion_items(brand);
CREATE INDEX IF NOT EXISTS idx_fashion_items_price ON fashion_items(price);
CREATE INDEX IF NOT EXISTS idx_fashion_items_sustainability ON fashion_items(sustainability_score);

-- User wardrobe table (Modaics digital wardrobe feature)
CREATE TABLE IF NOT EXISTS user_wardrobe (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    
    -- Item details
    image_url TEXT,
    thumbnail_url TEXT,
    embedding vector(768),  -- Same CLIP embeddings for search
    
    item_name TEXT NOT NULL,
    category VARCHAR(50),
    brand VARCHAR(100),
    size VARCHAR(20),
    color VARCHAR(50),
    material VARCHAR(100),
    
    -- Purchase info
    purchase_date DATE,
    purchase_price NUMERIC(10, 2),
    estimated_value NUMERIC(10, 2),
    
    -- Usage tracking
    times_worn INTEGER DEFAULT 0,
    last_worn_date DATE,
    
    -- Listing status
    is_listed_for_sale BOOLEAN DEFAULT FALSE,
    is_listed_for_swap BOOLEAN DEFAULT FALSE,
    is_listed_for_rent BOOLEAN DEFAULT FALSE,
    sale_price NUMERIC(10, 2),
    rental_price_daily NUMERIC(10, 2),
    
    -- Sustainability
    sustainability_score INTEGER,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wardrobe_user ON user_wardrobe(user_id);
CREATE INDEX IF NOT EXISTS idx_wardrobe_embedding 
ON user_wardrobe 
USING hnsw (embedding vector_cosine_ops);

-- Users table (for authentication and profile)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(100) PRIMARY KEY,  -- Firebase UID or Apple ID
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    
    -- Profile
    bio TEXT,
    profile_image_url TEXT,
    location VARCHAR(100),
    
    -- User type
    user_type VARCHAR(20) DEFAULT 'consumer' CHECK (user_type IN ('consumer', 'brand', 'admin')),
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- Sustainability metrics
    eco_points INTEGER DEFAULT 0,
    total_items_swapped INTEGER DEFAULT 0,
    total_items_sold INTEGER DEFAULT 0,
    co2_saved_kg NUMERIC(10, 2) DEFAULT 0,
    water_saved_liters NUMERIC(10, 2) DEFAULT 0,
    
    -- Social
    following_count INTEGER DEFAULT 0,
    followers_count INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Transactions table (for sales, swaps, rentals)
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    
    -- Transaction type
    type VARCHAR(20) CHECK (type IN ('purchase', 'swap', 'rental')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded')),
    
    -- Parties
    seller_id VARCHAR(100) REFERENCES users(id),
    buyer_id VARCHAR(100) REFERENCES users(id),
    
    -- Item (can be from fashion_items or user_wardrobe)
    item_type VARCHAR(20) CHECK (item_type IN ('marketplace', 'wardrobe')),
    item_id INTEGER NOT NULL,
    
    -- Financial
    price NUMERIC(10, 2),
    platform_fee NUMERIC(10, 2),
    seller_payout NUMERIC(10, 2),
    
    -- Rental specific
    rental_start_date DATE,
    rental_end_date DATE,
    
    -- Shipping
    tracking_number VARCHAR(100),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transactions_seller ON transactions(seller_id);
CREATE INDEX IF NOT EXISTS idx_transactions_buyer ON transactions(buyer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);

-- Events table (for swaps, pop-ups, workshops)
CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    
    -- Event details
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) CHECK (event_type IN ('swap', 'popup', 'workshop', 'other')),
    
    -- Organizer
    organizer_id VARCHAR(100) REFERENCES users(id),
    organizer_name VARCHAR(100),
    
    -- Location
    venue_name VARCHAR(200),
    address TEXT,
    city VARCHAR(100),
    latitude NUMERIC(10, 6),
    longitude NUMERIC(10, 6),
    
    -- Timing
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    
    -- Capacity
    max_attendees INTEGER,
    current_attendees INTEGER DEFAULT 0,
    
    -- Pricing
    is_free BOOLEAN DEFAULT TRUE,
    ticket_price NUMERIC(10, 2),
    platform_placement_fee NUMERIC(10, 2),  -- $50/event
    
    -- Status
    status VARCHAR(20) DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
    
    -- Images
    banner_image_url TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_organizer ON events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_city ON events(city);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON events(start_time);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);

-- Event attendees (many-to-many relationship)
CREATE TABLE IF NOT EXISTS event_attendees (
    event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
    user_id VARCHAR(100) REFERENCES users(id) ON DELETE CASCADE,
    rsvp_status VARCHAR(20) DEFAULT 'going' CHECK (rsvp_status IN ('going', 'interested', 'not_going')),
    checked_in BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (event_id, user_id)
);

-- Social follows (many-to-many)
CREATE TABLE IF NOT EXISTS user_follows (
    follower_id VARCHAR(100) REFERENCES users(id) ON DELETE CASCADE,
    following_id VARCHAR(100) REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower ON user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON user_follows(following_id);

-- Likes (for items in marketplace or wardrobe)
CREATE TABLE IF NOT EXISTS item_likes (
    user_id VARCHAR(100) REFERENCES users(id) ON DELETE CASCADE,
    item_type VARCHAR(20) CHECK (item_type IN ('marketplace', 'wardrobe')),
    item_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, item_type, item_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_user ON item_likes(user_id);

-- Style challenges (gamification)
CREATE TABLE IF NOT EXISTS style_challenges (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    theme VARCHAR(100),  -- e.g., "Zero-Waste Outfit", "Vintage Denim"
    
    -- Timing
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Rewards
    eco_points_reward INTEGER DEFAULT 50,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('upcoming', 'active', 'completed')),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW()
);

-- Challenge submissions
CREATE TABLE IF NOT EXISTS challenge_submissions (
    id SERIAL PRIMARY KEY,
    challenge_id INTEGER REFERENCES style_challenges(id) ON DELETE CASCADE,
    user_id VARCHAR(100) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Submission
    image_url TEXT NOT NULL,
    embedding vector(768),  -- CLIP embedding for validation
    caption TEXT,
    
    -- Validation
    theme_match_score NUMERIC(3, 2),  -- 0.00 to 1.00 (CLIP similarity)
    is_approved BOOLEAN DEFAULT FALSE,
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    
    -- Metadata
    submitted_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(challenge_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_submissions_challenge ON challenge_submissions(challenge_id);
CREATE INDEX IF NOT EXISTS idx_submissions_user ON challenge_submissions(user_id);

-- Analytics table (for tracking item views, searches, etc.)
CREATE TABLE IF NOT EXISTS analytics_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,  -- 'view', 'search', 'click', 'like'
    user_id VARCHAR(100),
    
    -- Event data (JSONB for flexibility)
    event_data JSONB,
    
    -- Context
    platform VARCHAR(20) CHECK (platform IN ('ios', 'web', 'api')),
    user_agent TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_user ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_created ON analytics_events(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_fashion_items_updated_at BEFORE UPDATE ON fashion_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_wardrobe_updated_at BEFORE UPDATE ON user_wardrobe
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SKETCHBOOK FEATURE TABLES
-- Brand-facing workspace for WIPs, drops, collaborations, events, and polls
-- ============================================================================

-- Sketchbooks (one per brand)
CREATE TABLE IF NOT EXISTS sketchbooks (
    id SERIAL PRIMARY KEY,
    brand_id VARCHAR(100) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Basic info
    title VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Access control
    access_policy VARCHAR(20) DEFAULT 'publicRead' CHECK (access_policy IN ('publicRead', 'membersOnly')),
    membership_rule VARCHAR(50) DEFAULT 'free' CHECK (membership_rule IN ('free', 'inviteOnly', 'minSpend')),
    
    -- Membership rule parameters (for minSpend)
    min_spend_amount NUMERIC(10, 2),
    min_spend_window_months INTEGER,
    
    -- Stats
    members_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(brand_id)  -- One sketchbook per brand
);

CREATE INDEX IF NOT EXISTS idx_sketchbooks_brand ON sketchbooks(brand_id);
CREATE INDEX IF NOT EXISTS idx_sketchbooks_access ON sketchbooks(access_policy);

-- Sketchbook posts (updates, events, drops, polls, moodboards)
CREATE TABLE IF NOT EXISTS sketchbook_posts (
    id SERIAL PRIMARY KEY,
    sketchbook_id INTEGER NOT NULL REFERENCES sketchbooks(id) ON DELETE CASCADE,
    author_user_id VARCHAR(100) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Post content
    post_type VARCHAR(20) NOT NULL CHECK (post_type IN ('update', 'event', 'drop', 'poll', 'moodboard')),
    title VARCHAR(200) NOT NULL,
    body TEXT,
    
    -- Media (JSON array of URLs)
    media JSONB DEFAULT '[]',
    
    -- Tags
    tags TEXT[],
    
    -- Visibility
    visibility VARCHAR(20) DEFAULT 'public' CHECK (visibility IN ('public', 'membersOnly')),
    
    -- Poll data (only for poll posts)
    poll_question TEXT,
    poll_options JSONB,  -- [{"id": "opt1", "label": "Option 1", "votes": 0}]
    poll_closes_at TIMESTAMP,
    
    -- Event data (only for event posts)
    event_id INTEGER REFERENCES events(id) ON DELETE SET NULL,
    event_highlight TEXT,
    
    -- Engagement
    views_count INTEGER DEFAULT 0,
    reactions_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sketchbook_posts_sketchbook ON sketchbook_posts(sketchbook_id);
CREATE INDEX IF NOT EXISTS idx_sketchbook_posts_author ON sketchbook_posts(author_user_id);
CREATE INDEX IF NOT EXISTS idx_sketchbook_posts_type ON sketchbook_posts(post_type);
CREATE INDEX IF NOT EXISTS idx_sketchbook_posts_created ON sketchbook_posts(created_at DESC);

-- Sketchbook memberships (tracks who has access to members-only sketchbooks)
CREATE TABLE IF NOT EXISTS sketchbook_memberships (
    id SERIAL PRIMARY KEY,
    sketchbook_id INTEGER NOT NULL REFERENCES sketchbooks(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('pending', 'active', 'revoked')),
    
    -- How did they get access?
    join_source VARCHAR(30) CHECK (join_source IN ('autoFromSpend', 'manualInvite', 'requestApproved', 'free')),
    
    -- Metadata
    joined_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(sketchbook_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_memberships_sketchbook ON sketchbook_memberships(sketchbook_id);
CREATE INDEX IF NOT EXISTS idx_memberships_user ON sketchbook_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_status ON sketchbook_memberships(status);

-- Sketchbook poll votes (tracks individual votes on poll posts)
CREATE TABLE IF NOT EXISTS sketchbook_poll_votes (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES sketchbook_posts(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    option_id VARCHAR(50) NOT NULL,  -- Matches the "id" in poll_options JSONB
    
    -- Metadata
    voted_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(post_id, user_id)  -- One vote per user per poll
);

CREATE INDEX IF NOT EXISTS idx_poll_votes_post ON sketchbook_poll_votes(post_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_user ON sketchbook_poll_votes(user_id);

-- Sketchbook post reactions (likes, etc.)
CREATE TABLE IF NOT EXISTS sketchbook_reactions (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES sketchbook_posts(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reaction_type VARCHAR(20) DEFAULT 'like' CHECK (reaction_type IN ('like', 'love', 'fire', 'eyes')),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(post_id, user_id, reaction_type)
);

CREATE INDEX IF NOT EXISTS idx_reactions_post ON sketchbook_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON sketchbook_reactions(user_id);

-- Sketchbook post comments
CREATE TABLE IF NOT EXISTS sketchbook_comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES sketchbook_posts(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Content
    body TEXT NOT NULL,
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post ON sketchbook_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user ON sketchbook_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created ON sketchbook_comments(created_at DESC);

-- Triggers for Sketchbook tables
CREATE TRIGGER update_sketchbooks_updated_at BEFORE UPDATE ON sketchbooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sketchbook_posts_updated_at BEFORE UPDATE ON sketchbook_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sketchbook_comments_updated_at BEFORE UPDATE ON sketchbook_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample sustainability scoring for known sustainable brands
-- (Will be populated after data import)
COMMENT ON TABLE fashion_items IS 'Marketplace items scraped from Depop, Grailed, Vinted with CLIP embeddings';
COMMENT ON TABLE user_wardrobe IS 'User-owned items in digital wardrobe, searchable with same CLIP embeddings';
COMMENT ON COLUMN fashion_items.embedding IS '768-dimensional CLIP embeddings from sentence-transformers/clip-ViT-B-32';
COMMENT ON COLUMN user_wardrobe.embedding IS 'Same CLIP embeddings used for marketplace search';
COMMENT ON TABLE sketchbooks IS 'Brand workspaces for sharing WIPs, drops, events, and polls with their community';
COMMENT ON TABLE sketchbook_posts IS 'Posts within sketchbooks - updates, events, drops, polls, moodboards';
COMMENT ON TABLE sketchbook_memberships IS 'Tracks user access to members-only sketchbooks';
