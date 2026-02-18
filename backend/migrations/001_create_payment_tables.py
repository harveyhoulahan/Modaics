"""
Database Migration Script for Payment Processing
Creates tables for transactions, subscriptions, and payment-related data
"""

MIGRATION_SQL = """
-- ============================================================================
-- Payment Processing Tables
-- ============================================================================

-- Users table extension for Stripe integration
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_account_id VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_account_status VARCHAR(50) DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS idx_users_stripe_customer ON users(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_users_stripe_account ON users(stripe_account_id);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id VARCHAR(255) NOT NULL REFERENCES users(id),
    seller_id VARCHAR(255) REFERENCES users(id),
    item_id INTEGER REFERENCES fashion_items(id),
    
    -- Payment details
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    platform_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
    seller_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    
    -- Status and type
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    type VARCHAR(50) NOT NULL,
    description TEXT,
    
    -- Stripe integration
    stripe_payment_intent_id VARCHAR(255),
    stripe_charge_id VARCHAR(255),
    stripe_payment_status VARCHAR(50),
    failure_message TEXT,
    
    -- Refund information
    refunded_at TIMESTAMP,
    refund_amount DECIMAL(10, 2),
    refund_reason TEXT,
    
    -- Metadata
    metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Indexes for transactions
CREATE INDEX IF NOT EXISTS idx_transactions_buyer ON transactions(buyer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_seller ON transactions(seller_id);
CREATE INDEX IF NOT EXISTS idx_transactions_item ON transactions(item_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_stripe_pi ON transactions(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- Subscription plans table
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    interval VARCHAR(50) DEFAULT 'month', -- month, year
    tier VARCHAR(50) NOT NULL, -- basic, pro, enterprise
    features JSONB,
    stripe_price_id VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    brand_id VARCHAR(255) REFERENCES users(id),
    
    -- Subscription status
    status VARCHAR(50) NOT NULL DEFAULT 'incomplete',
    current_period_start TIMESTAMP NOT NULL,
    current_period_end TIMESTAMP NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    cancelled_at TIMESTAMP,
    
    -- Stripe integration
    stripe_subscription_id VARCHAR(255),
    stripe_payment_intent_id VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan ON user_subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_brand ON user_subscriptions(brand_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_period_end ON user_subscriptions(current_period_end);

-- Payment methods table (for saved cards)
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    stripe_payment_method_id VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- card, bank_transfer, etc.
    
    -- Card details (last 4 only - never store full card numbers)
    card_last4 VARCHAR(4),
    card_brand VARCHAR(50),
    card_exp_month INTEGER,
    card_exp_year INTEGER,
    
    -- Billing details
    billing_name VARCHAR(255),
    billing_email VARCHAR(255),
    billing_address JSONB,
    
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_methods_user ON payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_stripe ON payment_methods(stripe_payment_method_id);

-- Disputes table
CREATE TABLE IF NOT EXISTS disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id),
    stripe_dispute_id VARCHAR(255) NOT NULL,
    
    status VARCHAR(50) NOT NULL,
    reason VARCHAR(255),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    evidence_due_by TIMESTAMP,
    evidence_submitted_at TIMESTAMP,
    evidence JSONB,
    
    resolved_at TIMESTAMP,
    resolution VARCHAR(50),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_disputes_transaction ON disputes(transaction_id);
CREATE INDEX IF NOT EXISTS idx_disputes_status ON disputes(status);

-- Payouts table for sellers
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id VARCHAR(255) NOT NULL REFERENCES users(id),
    
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    
    stripe_payout_id VARCHAR(255),
    stripe_transfer_id VARCHAR(255),
    
    bank_account_last4 VARCHAR(4),
    
    scheduled_at TIMESTAMP,
    processed_at TIMESTAMP,
    failed_at TIMESTAMP,
    failure_message TEXT,
    
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payouts_seller ON payouts(seller_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);
CREATE INDEX IF NOT EXISTS idx_payouts_scheduled ON payouts(scheduled_at);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers
DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON user_subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payment_methods_updated_at ON payment_methods;
CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Seed Data
-- ============================================================================

-- Insert default subscription plans
INSERT INTO subscription_plans (name, description, price, tier, features, stripe_price_id)
VALUES 
    (
        'Basic',
        'Free tier with community access',
        0.00,
        'basic',
        '["1 event per month", "Community posts", "Basic analytics"]',
        'price_basic_free'
    ),
    (
        'Pro',
        'Professional tier for growing brands',
        49.99,
        'pro',
        '["5 events per month", "Sustainability Badge application", "Advanced analytics", "Priority support"]',
        'price_pro_monthly'
    ),
    (
        'Enterprise',
        'Full-featured tier for established brands',
        199.99,
        'enterprise',
        '["Unlimited events", "FibreTrace integration", "Custom AI insights", "Dedicated account manager", "API access"]',
        'price_enterprise_monthly'
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Views for reporting
-- ============================================================================

-- Daily transaction summary view
CREATE OR REPLACE VIEW daily_transaction_summary AS
SELECT 
    DATE(created_at) as date,
    COUNT(*) as transaction_count,
    SUM(amount) as total_volume,
    SUM(platform_fee) as total_fees,
    SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) as completed_volume,
    SUM(CASE WHEN status = 'refunded' THEN amount ELSE 0 END) as refunded_volume
FROM transactions
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Monthly revenue by type
CREATE OR REPLACE VIEW monthly_revenue_by_type AS
SELECT 
    DATE_TRUNC('month', created_at) as month,
    type,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    SUM(platform_fee) as platform_revenue
FROM transactions
WHERE status = 'completed'
GROUP BY DATE_TRUNC('month', created_at), type
ORDER BY month DESC, type;

"""


def run_migration():
    """Run the database migration"""
    import os
    import psycopg2
    import psycopg2.extras
    
    database_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5433/modaics")
    
    print("Running payment tables migration...")
    
    conn = psycopg2.connect(database_url)
    conn.autocommit = True
    
    try:
        with conn.cursor() as cur:
            cur.execute(MIGRATION_SQL)
        print("✅ Migration completed successfully!")
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    run_migration()
