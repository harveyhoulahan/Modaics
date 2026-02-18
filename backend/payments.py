"""
Payment Service Module for Modaics Backend
Handles Stripe PaymentIntents, subscriptions, webhooks, and transaction recording
"""
import os
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from enum import Enum

import stripe
from pydantic import BaseModel, Field

# Configure logging
logger = logging.getLogger(__name__)

# Initialize Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "sk_test_your_key_here")
stripe.api_version = "2024-06-20"

# Constants
PLATFORM_FEE_PERCENT = 0.10  # 10% platform fee
BUYER_FEE_DOMESTIC = 0.06     # 6% domestic buyer fee
BUYER_FEE_INTERNATIONAL = 0.03  # 3% international buyer fee
MINIMUM_TRANSACTION_AMOUNT = 0.50  # $0.50 minimum


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


class SubscriptionTier(str, Enum):
    BASIC = "basic"
    PRO = "pro"
    ENTERPRISE = "enterprise"


# ============================================================================
# Pydantic Models for API Requests/Responses
# ============================================================================

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


class TransactionResponse(BaseModel):
    """Transaction record response"""
    id: str
    buyer_id: str
    seller_id: Optional[str]
    item_id: Optional[str]
    amount: float
    currency: str
    platform_fee: float
    seller_amount: float
    status: TransactionStatus
    type: TransactionType
    description: str
    created_at: datetime
    updated_at: datetime
    metadata: Optional[Dict[str, Any]] = None


class SubscriptionResponse(BaseModel):
    """Subscription record response"""
    id: str
    user_id: str
    plan_id: str
    brand_id: str
    status: str
    current_period_start: datetime
    current_period_end: datetime
    cancel_at_period_end: bool
    created_at: datetime


# ============================================================================
# Payment Service Functions
# ============================================================================

async def get_or_create_stripe_customer(user_id: str, email: Optional[str] = None) -> str:
    """
    Get or create a Stripe customer for a Modaics user.
    
    Args:
        user_id: Modaics user ID
        email: User's email address
        
    Returns:
        Stripe customer ID
    """
    from . import db
    
    # Check if user already has a Stripe customer ID
    query = "SELECT stripe_customer_id FROM users WHERE id = $1"
    result = await db.fetch_one(query, [user_id])
    
    if result and result.get("stripe_customer_id"):
        return result["stripe_customer_id"]
    
    # Create new Stripe customer
    customer = stripe.Customer.create(
        metadata={"modaics_user_id": user_id},
        email=email
    )
    
    # Save to database
    update_query = """
        UPDATE users 
        SET stripe_customer_id = $1, updated_at = NOW()
        WHERE id = $2
    """
    await db.execute(update_query, [customer.id, user_id])
    
    logger.info(f"Created Stripe customer {customer.id} for user {user_id}")
    return customer.id


async def create_ephemeral_key(customer_id: str) -> str:
    """
    Create an ephemeral key for Stripe PaymentSheet.
    
    Args:
        customer_id: Stripe customer ID
        
    Returns:
        Ephemeral key secret
    """
    ephemeral_key = stripe.EphemeralKey.create(
        customer=customer_id,
        stripe_version="2024-06-20"
    )
    return ephemeral_key.secret


async def create_item_purchase_intent(
    buyer_id: str,
    request: ItemPurchaseRequest
) -> PaymentIntentResponse:
    """
    Create a PaymentIntent for an item purchase.
    
    Args:
        buyer_id: ID of the buyer
        request: Item purchase request details
        
    Returns:
        PaymentIntent response with client secret
    """
    # Validate minimum amount
    if request.total_amount < MINIMUM_TRANSACTION_AMOUNT:
        raise ValueError(f"Minimum transaction amount is ${MINIMUM_TRANSACTION_AMOUNT}")
    
    # Get or create Stripe customer
    customer_id = await get_or_create_stripe_customer(buyer_id)
    
    # Calculate fees
    platform_fee = request.amount * PLATFORM_FEE_PERCENT
    seller_amount = request.amount - platform_fee
    
    # Create payment intent
    payment_intent = stripe.PaymentIntent.create(
        amount=int(request.total_amount * 100),  # Convert to cents
        currency=request.currency.lower(),
        customer=customer_id,
        automatic_payment_methods={"enabled": True},
        metadata={
            "type": "item_purchase",
            "buyer_id": buyer_id,
            "seller_id": request.seller_id,
            "item_id": request.item_id,
            "original_amount": str(request.amount),
            "buyer_fee": str(request.buyer_fee),
            "platform_fee": str(platform_fee),
            "seller_amount": str(seller_amount),
            "is_international": str(request.is_international)
        },
        description=f"Purchase of item {request.item_id}",
        transfer_data={
            "destination": await get_seller_stripe_account(request.seller_id),
            "amount": int(seller_amount * 100)  # Amount seller receives
        } if await seller_has_connected_account(request.seller_id) else None
    )
    
    # Create transaction record
    transaction_id = await create_transaction_record(
        buyer_id=buyer_id,
        seller_id=request.seller_id,
        item_id=request.item_id,
        amount=request.total_amount,
        currency=request.currency,
        platform_fee=platform_fee + request.buyer_fee,
        seller_amount=seller_amount,
        type=TransactionType.ITEM_PURCHASE,
        description=f"Purchase of item {request.item_id}",
        stripe_payment_intent_id=payment_intent.id,
        metadata={
            "item_id": request.item_id,
            "original_price": request.amount,
            "buyer_fee": request.buyer_fee,
            "shipping_address": request.shipping_address
        }
    )
    
    # Create ephemeral key for PaymentSheet
    ephemeral_key = await create_ephemeral_key(customer_id)
    
    logger.info(f"Created payment intent {payment_intent.id} for transaction {transaction_id}")
    
    return PaymentIntentResponse(
        client_secret=payment_intent.client_secret,
        payment_intent_id=payment_intent.id,
        ephemeral_key=ephemeral_key,
        customer_id=customer_id,
        publishable_key=os.getenv("STRIPE_PUBLISHABLE_KEY", "pk_test_your_key"),
        amount=request.total_amount,
        currency=request.currency,
        status=payment_intent.status
    )


async def create_subscription_intent(
    user_id: str,
    request: SubscriptionRequest
) -> PaymentIntentResponse:
    """
    Create a PaymentIntent for brand subscription.
    
    Args:
        user_id: ID of the subscribing user
        request: Subscription request details
        
    Returns:
        PaymentIntent response with client secret
    """
    # Get subscription plan details
    plan = await get_subscription_plan(request.plan_id)
    if not plan:
        raise ValueError(f"Subscription plan {request.plan_id} not found")
    
    # Get or create Stripe customer
    customer_id = await get_or_create_stripe_customer(user_id)
    
    # Create payment intent for first payment
    payment_intent = stripe.PaymentIntent.create(
        amount=int(plan["price"] * 100),
        currency="usd",
        customer=customer_id,
        automatic_payment_methods={"enabled": True},
        setup_future_usage="off_session",  # Save payment method for future payments
        metadata={
            "type": "subscription",
            "user_id": user_id,
            "brand_id": request.brand_id,
            "plan_id": request.plan_id,
            "tier": request.tier.value
        },
        description=f"{plan['name']} subscription"
    )
    
    # Create subscription record
    await create_subscription_record(
        user_id=user_id,
        plan_id=request.plan_id,
        brand_id=request.brand_id,
        stripe_payment_intent_id=payment_intent.id
    )
    
    ephemeral_key = await create_ephemeral_key(customer_id)
    
    return PaymentIntentResponse(
        client_secret=payment_intent.client_secret,
        payment_intent_id=payment_intent.id,
        ephemeral_key=ephemeral_key,
        customer_id=customer_id,
        publishable_key=os.getenv("STRIPE_PUBLISHABLE_KEY", "pk_test_your_key"),
        amount=plan["price"],
        currency="usd",
        status=payment_intent.status
    )


async def create_p2p_transfer_intent(
    sender_id: str,
    request: P2PTransferRequest
) -> PaymentIntentResponse:
    """
    Create a PaymentIntent for P2P transfer.
    
    Args:
        sender_id: ID of the sender
        request: P2P transfer request details
        
    Returns:
        PaymentIntent response with client secret
    """
    if request.amount < MINIMUM_TRANSACTION_AMOUNT:
        raise ValueError(f"Minimum transfer amount is ${MINIMUM_TRANSACTION_AMOUNT}")
    
    customer_id = await get_or_create_stripe_customer(sender_id)
    
    # Small fee for P2P transfers to cover processing costs
    transfer_fee = request.amount * 0.02  # 2% fee
    total_amount = request.amount + transfer_fee
    
    payment_intent = stripe.PaymentIntent.create(
        amount=int(total_amount * 100),
        currency=request.currency.lower(),
        customer=customer_id,
        automatic_payment_methods={"enabled": True},
        metadata={
            "type": "p2p_transfer",
            "sender_id": sender_id,
            "recipient_id": request.recipient_id,
            "transfer_amount": str(request.amount),
            "transfer_fee": str(transfer_fee),
            "note": request.note or ""
        },
        description=f"Transfer to user {request.recipient_id}"
    )
    
    # Create transaction record
    await create_transaction_record(
        buyer_id=sender_id,
        seller_id=request.recipient_id,
        item_id=None,
        amount=total_amount,
        currency=request.currency,
        platform_fee=transfer_fee,
        seller_amount=request.amount,
        type=TransactionType.P2P_TRANSFER,
        description=request.note or f"Transfer to user {request.recipient_id}",
        stripe_payment_intent_id=payment_intent.id,
        metadata={
            "recipient_id": request.recipient_id,
            "transfer_amount": request.amount,
            "note": request.note
        }
    )
    
    ephemeral_key = await create_ephemeral_key(customer_id)
    
    return PaymentIntentResponse(
        client_secret=payment_intent.client_secret,
        payment_intent_id=payment_intent.id,
        ephemeral_key=ephemeral_key,
        customer_id=customer_id,
        publishable_key=os.getenv("STRIPE_PUBLISHABLE_KEY", "pk_test_your_key"),
        amount=total_amount,
        currency=request.currency,
        status=payment_intent.status
    )


async def confirm_payment(payment_intent_id: str) -> Dict[str, Any]:
    """
    Confirm a payment and update transaction status.
    
    Args:
        payment_intent_id: Stripe PaymentIntent ID
        
    Returns:
        Updated transaction record
    """
    from . import db
    
    # Retrieve payment intent from Stripe
    payment_intent = stripe.PaymentIntent.retrieve(payment_intent_id)
    
    # Update transaction status based on payment status
    status_mapping = {
        "succeeded": TransactionStatus.COMPLETED,
        "processing": TransactionStatus.PROCESSING,
        "requires_action": TransactionStatus.PENDING,
        "requires_capture": TransactionStatus.PENDING,
        "canceled": TransactionStatus.CANCELLED,
        "requires_payment_method": TransactionStatus.FAILED,
        "requires_confirmation": TransactionStatus.PENDING
    }
    
    new_status = status_mapping.get(payment_intent.status, TransactionStatus.PENDING)
    
    # Update transaction in database
    query = """
        UPDATE transactions
        SET status = $1, updated_at = NOW(),
            stripe_payment_status = $2
        WHERE stripe_payment_intent_id = $3
        RETURNING *
    """
    result = await db.fetch_one(query, [new_status.value, payment_intent.status, payment_intent_id])
    
    if not result:
        raise ValueError(f"Transaction not found for payment intent {payment_intent_id}")
    
    # If payment succeeded, handle post-payment actions
    if payment_intent.status == "succeeded":
        await handle_successful_payment(result)
    
    logger.info(f"Confirmed payment {payment_intent_id} with status {payment_intent.status}")
    
    return dict(result)


async def handle_successful_payment(transaction: Dict[str, Any]):
    """
    Handle post-payment success actions.
    
    Args:
        transaction: Transaction record
    """
    transaction_type = transaction.get("type")
    
    if transaction_type == TransactionType.ITEM_PURCHASE.value:
        # Update item status to sold
        item_id = transaction.get("item_id")
        if item_id:
            await mark_item_as_sold(item_id, transaction["buyer_id"])
        
        # Notify seller
        await notify_seller_of_sale(transaction["seller_id"], transaction)
        
    elif transaction_type == TransactionType.BRAND_SUBSCRIPTION.value:
        # Activate subscription
        await activate_subscription(transaction["buyer_id"], transaction.get("metadata", {}).get("plan_id"))
        
    elif transaction_type == TransactionType.P2P_TRANSFER.value:
        # Notify recipient
        metadata = transaction.get("metadata", {})
        recipient_id = metadata.get("recipient_id")
        if recipient_id:
            await notify_user_of_transfer(recipient_id, transaction)


async def handle_stripe_webhook(payload: bytes, signature: str) -> Dict[str, Any]:
    """
    Handle Stripe webhook events.
    
    Args:
        payload: Raw request body
        signature: Stripe signature header
        
    Returns:
        Event data
    """
    webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_your_secret")
    
    try:
        event = stripe.Webhook.construct_event(
            payload, signature, webhook_secret
        )
    except ValueError as e:
        logger.error(f"Invalid payload: {e}")
        raise ValueError("Invalid payload")
    except stripe.error.SignatureVerificationError as e:
        logger.error(f"Invalid signature: {e}")
        raise ValueError("Invalid signature")
    
    logger.info(f"Received webhook event: {event['type']}")
    
    # Handle different event types
    if event["type"] == "payment_intent.succeeded":
        payment_intent = event["data"]["object"]
        await confirm_payment(payment_intent["id"])
        
    elif event["type"] == "payment_intent.payment_failed":
        payment_intent = event["data"]["object"]
        await handle_failed_payment(payment_intent)
        
    elif event["type"] == "charge.refunded":
        charge = event["data"]["object"]
        await handle_refund(charge)
        
    elif event["type"] == "customer.subscription.created":
        subscription = event["data"]["object"]
        await handle_subscription_created(subscription)
        
    elif event["type"] == "customer.subscription.deleted":
        subscription = event["data"]["object"]
        await handle_subscription_cancelled(subscription)
    
    return {"status": "success", "event_type": event["type"]}


async def handle_failed_payment(payment_intent: Dict[str, Any]):
    """Handle failed payment"""
    from . import db
    
    query = """
        UPDATE transactions
        SET status = $1, updated_at = NOW(),
            failure_message = $2
        WHERE stripe_payment_intent_id = $3
    """
    error_message = payment_intent.get("last_payment_error", {}).get("message", "Unknown error")
    await db.execute(query, [TransactionStatus.FAILED.value, error_message, payment_intent["id"]])
    
    logger.warning(f"Payment failed: {payment_intent['id']} - {error_message}")


async def handle_refund(charge: Dict[str, Any]):
    """Handle refund"""
    from . import db
    
    query = """
        UPDATE transactions
        SET status = $1, updated_at = NOW(),
            refunded_at = NOW(),
            refund_amount = $2
        WHERE stripe_charge_id = $3
    """
    refund_amount = charge.get("amount_refunded", 0) / 100  # Convert from cents
    await db.execute(query, [TransactionStatus.REFUNDED.value, refund_amount, charge["id"]])
    
    logger.info(f"Refund processed for charge {charge['id']}")


# ============================================================================
# Database Helper Functions
# ============================================================================

async def create_transaction_record(
    buyer_id: str,
    seller_id: Optional[str],
    item_id: Optional[str],
    amount: float,
    currency: str,
    platform_fee: float,
    seller_amount: float,
    type: TransactionType,
    description: str,
    stripe_payment_intent_id: str,
    metadata: Optional[Dict[str, Any]] = None
) -> str:
    """Create a transaction record in the database"""
    from . import db
    import json
    
    query = """
        INSERT INTO transactions (
            buyer_id, seller_id, item_id, amount, currency,
            platform_fee, seller_amount, status, type, description,
            stripe_payment_intent_id, metadata, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
        RETURNING id
    """
    
    result = await db.fetch_one(query, [
        buyer_id, seller_id, item_id, amount, currency.upper(),
        platform_fee, seller_amount, TransactionStatus.PENDING.value,
        type.value, description, stripe_payment_intent_id,
        json.dumps(metadata) if metadata else None
    ])
    
    return result["id"]


async def get_transaction(transaction_id: str) -> Optional[Dict[str, Any]]:
    """Get a transaction by ID"""
    from . import db
    
    query = "SELECT * FROM transactions WHERE id = $1"
    return await db.fetch_one(query, [transaction_id])


async def get_user_transactions(user_id: str, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
    """Get transactions for a user (as buyer or seller)"""
    from . import db
    
    query = """
        SELECT * FROM transactions
        WHERE buyer_id = $1 OR seller_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
    """
    return await db.fetch_all(query, [user_id, limit, offset])


async def create_subscription_record(
    user_id: str,
    plan_id: str,
    brand_id: str,
    stripe_payment_intent_id: str
):
    """Create a subscription record"""
    from . import db
    
    # Calculate period dates
    current_period_start = datetime.utcnow()
    current_period_end = current_period_start + timedelta(days=30)  # Monthly subscription
    
    query = """
        INSERT INTO user_subscriptions (
            user_id, plan_id, brand_id, status,
            current_period_start, current_period_end,
            cancel_at_period_end, stripe_payment_intent_id,
            created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        RETURNING id
    """
    
    await db.fetch_one(query, [
        user_id, plan_id, brand_id, "pending",
        current_period_start, current_period_end,
        False, stripe_payment_intent_id
    ])


async def get_subscription_plan(plan_id: str) -> Optional[Dict[str, Any]]:
    """Get subscription plan details"""
    from . import db
    
    query = "SELECT * FROM subscription_plans WHERE id = $1"
    return await db.fetch_one(query, [plan_id])


async def get_user_subscription(user_id: str) -> Optional[Dict[str, Any]]:
    """Get user's active subscription"""
    from . import db
    
    query = """
        SELECT * FROM user_subscriptions
        WHERE user_id = $1 AND status = 'active'
        AND current_period_end > NOW()
        ORDER BY created_at DESC
        LIMIT 1
    """
    return await db.fetch_one(query, [user_id])


async def cancel_subscription(subscription_id: str):
    """Cancel a subscription"""
    from . import db
    
    query = """
        UPDATE user_subscriptions
        SET cancel_at_period_end = TRUE, updated_at = NOW()
        WHERE id = $1
        RETURNING stripe_subscription_id
    """
    result = await db.fetch_one(query, [subscription_id])
    
    if result and result.get("stripe_subscription_id"):
        # Cancel in Stripe
        stripe.Subscription.delete(result["stripe_subscription_id"])


# ============================================================================
# Helper Functions
# ============================================================================

async def get_seller_stripe_account(seller_id: str) -> Optional[str]:
    """Get seller's connected Stripe account ID"""
    from . import db
    
    query = "SELECT stripe_account_id FROM users WHERE id = $1"
    result = await db.fetch_one(query, [seller_id])
    return result.get("stripe_account_id") if result else None


async def seller_has_connected_account(seller_id: str) -> bool:
    """Check if seller has a connected Stripe account"""
    account_id = await get_seller_stripe_account(seller_id)
    return account_id is not None


async def mark_item_as_sold(item_id: str, buyer_id: str):
    """Mark an item as sold"""
    from . import db
    
    query = """
        UPDATE fashion_items
        SET status = 'sold', buyer_id = $1, sold_at = NOW()
        WHERE id = $2
    """
    await db.execute(query, [buyer_id, item_id])


async def notify_seller_of_sale(seller_id: str, transaction: Dict[str, Any]):
    """Send notification to seller about sale"""
    # Implementation depends on your notification system
    logger.info(f"Notifying seller {seller_id} of sale {transaction['id']}")


async def activate_subscription(user_id: str, plan_id: Optional[str]):
    """Activate a subscription after payment"""
    from . import db
    
    query = """
        UPDATE user_subscriptions
        SET status = 'active', updated_at = NOW()
        WHERE user_id = $1 AND plan_id = $2 AND status = 'pending'
    """
    if plan_id:
        await db.execute(query, [user_id, plan_id])


async def notify_user_of_transfer(user_id: str, transaction: Dict[str, Any]):
    """Notify user of received transfer"""
    logger.info(f"Notifying user {user_id} of transfer {transaction['id']}")


async def handle_subscription_created(subscription: Dict[str, Any]):
    """Handle Stripe subscription created event"""
    logger.info(f"Subscription created: {subscription['id']}")


async def handle_subscription_cancelled(subscription: Dict[str, Any]):
    """Handle Stripe subscription cancelled event"""
    from . import db
    
    query = """
        UPDATE user_subscriptions
        SET status = 'cancelled', updated_at = NOW()
        WHERE stripe_subscription_id = $1
    """
    await db.execute(query, [subscription["id"]])
    logger.info(f"Subscription cancelled: {subscription['id']}")


# ============================================================================
# Fee Calculation Functions
# ============================================================================

def calculate_buyer_fee(amount: float, is_international: bool = False) -> float:
    """Calculate buyer fee for a transaction"""
    fee_rate = BUYER_FEE_INTERNATIONAL if is_international else BUYER_FEE_DOMESTIC
    return amount * fee_rate


def calculate_platform_fee(amount: float) -> float:
    """Calculate platform fee for a transaction"""
    return amount * PLATFORM_FEE_PERCENT


def calculate_seller_receivable(amount: float) -> float:
    """Calculate amount seller receives after platform fee"""
    return amount * (1 - PLATFORM_FEE_PERCENT)
