from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class SearchRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded image data")


class DepopItem(BaseModel):
    id: int
    external_id: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    url: Optional[str] = None
    image_url: Optional[str] = None
    distance: Optional[float] = None
    redirect_url: Optional[str] = None
    source: Optional[str] = None


class SearchResponse(BaseModel):
    items: List[DepopItem]


# ============================================================================
# Payment Models
# ============================================================================

class TransactionStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"
    DISPUTED = "disputed"
    CANCELLED = "cancelled"


class TransactionType(str, Enum):
    ITEM_PURCHASE = "item_purchase"
    BRAND_SUBSCRIPTION = "brand_subscription"
    EVENT_TICKET = "event_ticket"
    DEPOSIT = "deposit"
    WITHDRAWAL = "withdrawal"
    REFUND = "refund"
    P2P_TRANSFER = "p2p_transfer"


class PaymentIntentRequest(BaseModel):
    """Base payment intent request"""
    amount: float = Field(..., gt=0, description="Amount in dollars")
    currency: str = Field(default="usd", description="Currency code (default: usd)")
    description: Optional[str] = None
    metadata: Optional[Dict[str, str]] = None


class ItemPurchaseRequest(PaymentIntentRequest):
    """Request for item purchase payment intent"""
    item_id: str
    seller_id: str
    buyer_fee: float
    total_amount: float
    is_international: bool = False
    shipping_address: Optional[Dict[str, str]] = None


class SubscriptionTier(str, Enum):
    BASIC = "basic"
    PRO = "pro"
    ENTERPRISE = "enterprise"


class SubscriptionRequest(BaseModel):
    """Request for brand subscription"""
    plan_id: str
    brand_id: str
    tier: SubscriptionTier


class P2PTransferRequest(PaymentIntentRequest):
    """Request for P2P transfer"""
    recipient_id: str
    note: Optional[str] = None


class EventTicketRequest(PaymentIntentRequest):
    """Request for event ticket purchase"""
    event_id: str
    quantity: int = Field(..., ge=1, le=10)


class PaymentIntentResponse(BaseModel):
    """Response containing Stripe PaymentIntent client secret"""
    client_secret: str
    payment_intent_id: str
    ephemeral_key: Optional[str] = None
    customer_id: Optional[str] = None
    publishable_key: str
    amount: float
    currency: str
    status: str


class TransactionMetadata(BaseModel):
    """Transaction metadata"""
    item_title: Optional[str] = None
    item_image_url: Optional[str] = None
    brand_name: Optional[str] = None
    subscription_tier: Optional[str] = None
    event_name: Optional[str] = None
    shipping_address: Optional[Dict[str, str]] = None


class Transaction(BaseModel):
    """Transaction record"""
    id: str
    buyer_id: str
    seller_id: Optional[str] = None
    item_id: Optional[str] = None
    amount: float
    currency: str
    platform_fee: float
    seller_amount: float
    status: TransactionStatus
    type: TransactionType
    description: str
    created_at: datetime
    updated_at: datetime
    metadata: Optional[TransactionMetadata] = None
    stripe_payment_intent_id: Optional[str] = None
    stripe_charge_id: Optional[str] = None


class SubscriptionStatus(str, Enum):
    ACTIVE = "active"
    CANCELLED = "cancelled"
    PAST_DUE = "past_due"
    UNPAID = "unpaid"
    INCOMPLETE = "incomplete"


class UserSubscription(BaseModel):
    """User subscription record"""
    id: str
    user_id: str
    plan_id: str
    brand_id: str
    status: SubscriptionStatus
    current_period_start: datetime
    current_period_end: datetime
    cancel_at_period_end: bool
    created_at: datetime
    stripe_subscription_id: Optional[str] = None
    stripe_payment_intent_id: Optional[str] = None


class FeeStructureResponse(BaseModel):
    """Fee structure response"""
    platform_fee_percent: float
    buyer_fee_domestic: float
    buyer_fee_international: float
    minimum_transaction_amount: float
