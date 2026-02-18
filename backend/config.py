import os


# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5433/modaics")

# OpenAI Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
EMBEDDING_PROVIDER = os.getenv("EMBEDDING_PROVIDER", "clip")  # options: openai, clip
OPENAI_EMBEDDING_MODEL = os.getenv("OPENAI_EMBEDDING_MODEL", "image-embedding-3-large")
EMBEDDING_DIMENSION = 768
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "20"))

# Stripe Configuration
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "sk_test_your_key_here")
STRIPE_PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY", "pk_test_your_key_here")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_your_secret_here")

# Stripe Connect (for marketplace payouts to sellers)
STRIPE_CONNECT_CLIENT_ID = os.getenv("STRIPE_CONNECT_CLIENT_ID")
STRIPE_PLATFORM_FEE_PERCENT = float(os.getenv("STRIPE_PLATFORM_FEE_PERCENT", "10.0"))

# Payment Settings
MINIMUM_TRANSACTION_AMOUNT = float(os.getenv("MINIMUM_TRANSACTION_AMOUNT", "0.50"))
BUYER_FEE_DOMESTIC = float(os.getenv("BUYER_FEE_DOMESTIC", "6.0"))  # percentage
BUYER_FEE_INTERNATIONAL = float(os.getenv("BUYER_FEE_INTERNATIONAL", "3.0"))  # percentage
P2P_TRANSFER_FEE = float(os.getenv("P2P_TRANSFER_FEE", "2.0"))  # percentage

# Apple Pay Configuration
APPLE_PAY_MERCHANT_ID = os.getenv("APPLE_PAY_MERCHANT_ID", "merchant.com.modaics")
APPLE_PAY_MERCHANT_CERTIFICATE = os.getenv("APPLE_PAY_MERCHANT_CERTIFICATE")

# API Configuration
API_BASE_URL = os.getenv("API_BASE_URL", "https://api.modaics.com")
FRONTEND_URL = os.getenv("FRONTEND_URL", "https://modaics.com")
