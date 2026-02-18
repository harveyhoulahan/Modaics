# Modaics Payment Processing Integration

Complete Stripe-based payment processing system for the Modaics iOS app, supporting in-app purchases, P2P transfers, and brand subscriptions (Sketchbook membership).

## Features

- **Item Purchases**: Buy items from other users with buyer protection fees
- **Brand Subscriptions**: Subscribe to brand Sketchbooks (Basic, Pro, Enterprise tiers)
- **P2P Transfers**: Send money directly to other users
- **Apple Pay Support**: Quick checkout with Apple Pay
- **Secure**: PCI-compliant via Stripe PaymentIntents (never stores card details)
- **International Support**: Reduced fees for international transactions

## Architecture

### iOS Components

```
IOS/
├── Services/
│   └── PaymentService.swift          # Main payment service with Stripe SDK
├── Views/Payment/
│   ├── PaymentButton.swift           # Reusable payment button components
│   ├── PaymentConfirmationView.swift # Post-payment confirmation screen
│   ├── TransactionHistoryView.swift  # Wallet and transaction history
│   ├── PurchaseFlowView.swift        # Complete item purchase flow
│   ├── SubscriptionFlowView.swift    # Brand subscription flow
│   └── P2PTransferView.swift         # P2P money transfer flow
```

### Backend Components

```
backend/
├── payments.py                       # Payment service with Stripe integration
├── app.py                            # FastAPI endpoints for payments
├── models.py                         # Payment-related Pydantic models
├── config.py                         # Stripe and payment configuration
└── migrations/
    └── 001_create_payment_tables.py  # Database migration for payment tables
```

## Setup Instructions

### 1. iOS Setup

#### Install Stripe SDK

Add to your `Package.swift` or use Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/stripe/stripe-ios-spm", from: "23.0.0")
]
```

#### Configure Info.plist

Add to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for scanning cards</string>

<key>StripePublishableKey</key>
<string>$(STRIPE_PUBLISHABLE_KEY)</string>
```

#### Apple Pay Configuration

1. Enable Apple Pay in your App ID on Apple Developer Portal
2. Create a Merchant ID (e.g., `merchant.com.modaics`)
3. Add the Merchant ID to your App ID
4. Create a Payment Processing Certificate
5. Upload the CSR to Stripe Dashboard

### 2. Backend Setup

#### Environment Variables

Create a `.env` file:

```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Optional: Stripe Connect for marketplace payouts
STRIPE_CONNECT_CLIENT_ID=ca_...

# Payment Settings
PLATFORM_FEE_PERCENT=10.0
BUYER_FEE_DOMESTIC=6.0
BUYER_FEE_INTERNATIONAL=3.0
P2P_TRANSFER_FEE=2.0

# Apple Pay
APPLE_PAY_MERCHANT_ID=merchant.com.modaics
```

#### Install Dependencies

```bash
pip install stripe asyncpg
```

#### Run Database Migration

```bash
cd backend
python migrations/001_create_payment_tables.py
```

#### Start Server

```bash
python -m backend.app
```

### 3. Stripe Dashboard Configuration

#### Webhook Endpoints

Configure webhook endpoint in Stripe Dashboard:

- **URL**: `https://api.modaics.com/webhooks/stripe`
- **Events to listen for**:
  - `payment_intent.succeeded`
  - `payment_intent.payment_failed`
  - `charge.refunded`
  - `customer.subscription.created`
  - `customer.subscription.deleted`

#### Products and Prices

Create subscription plans in Stripe Dashboard:

1. **Basic (Free)**
   - Price ID: `price_basic_free`
   - Amount: $0

2. **Pro Membership**
   - Price ID: `price_pro_monthly`
   - Amount: $9.99/month

3. **Enterprise/VIP**
   - Price ID: `price_vip_monthly`
   - Amount: $29.99/month

## Usage Examples

### Item Purchase

```swift
// In your item detail view
Button("Buy Now") {
    showPurchaseFlow = true
}
.sheet(isPresented: $showPurchaseFlow) {
    PurchaseFlowView(item: itemForPurchase)
}
```

### Brand Subscription

```swift
// In brand profile view
Button("Subscribe") {
    showSubscriptionFlow = true
}
.sheet(isPresented: $showSubscriptionFlow) {
    SubscriptionFlowView(brand: brandForSubscription)
}
```

### P2P Transfer

```swift
// In user profile or wallet
Button("Send Money") {
    showTransferFlow = true
}
.sheet(isPresented: $showTransferFlow) {
    P2PTransferView()
}
```

### Transaction History

```swift
// In wallet tab
NavigationLink("Transaction History") {
    TransactionHistoryView()
}
```

## Fee Structure

| Transaction Type | Buyer Fee | Seller Fee | Platform Fee |
|-----------------|-----------|------------|--------------|
| Domestic Purchase | 6% | - | 10% of item price |
| International Purchase | 3% | - | 10% of item price |
| P2P Transfer | - | - | 2% |
| Subscription | - | - | Stripe fees only |

### Example Purchase Calculation

**Domestic Purchase ($100 item):**
- Item Price: $100.00
- Buyer Fee (6%): $6.00
- **Total Charged: $106.00**
- Platform Fee (10%): $10.00
- **Seller Receives: $90.00**

**International Purchase ($100 item):**
- Item Price: $100.00
- Buyer Fee (3%): $3.00
- **Total Charged: $103.00**
- Platform Fee (10%): $10.00
- **Seller Receives: $90.00**

## Security Considerations

1. **PCI Compliance**: We use Stripe PaymentIntents which are PCI-compliant. No card details ever touch our servers.

2. **Webhook Verification**: All Stripe webhooks are verified using the webhook secret.

3. **Authentication**: All payment endpoints require valid authentication tokens.

4. **Idempotency**: Payment intents are idempotent to prevent duplicate charges.

5. **Refund Policy**: Refunds can be requested within 30 days for eligible transactions.

## API Endpoints

### Payment Intents

- `POST /payments/item-purchase` - Create item purchase intent
- `POST /payments/subscription` - Create subscription intent
- `POST /payments/p2p-transfer` - Create P2P transfer intent
- `POST /payments/event-ticket` - Create event ticket intent
- `POST /payments/confirm` - Confirm payment

### Transactions

- `GET /transactions` - List user transactions
- `GET /transactions/{id}` - Get transaction details
- `POST /transactions/{id}/refund` - Request refund

### Subscriptions

- `GET /subscriptions/current` - Get current subscription
- `POST /subscriptions/{id}/cancel` - Cancel subscription

### Webhooks

- `POST /webhooks/stripe` - Stripe webhook handler

## Testing

### Test Cards (Stripe Test Mode)

```
Visa: 4242 4242 4242 4242
Mastercard: 5555 5555 5555 4444
Declined: 4000 0000 0000 0002
Require Auth: 4000 0025 0000 3155
```

Use any future expiry date and any 3-digit CVC.

### Test Apple Pay

In iOS Simulator:
1. Add a test card in Wallet
2. Use the test card for payments

## Troubleshooting

### Common Issues

1. **Payment sheet not appearing**
   - Check that `STRIPE_PUBLISHABLE_KEY` is set correctly
   - Verify the ephemeral key is being generated

2. **Webhooks not working**
   - Ensure webhook URL is publicly accessible
   - Verify webhook secret is correct
   - Check Stripe Dashboard for failed webhooks

3. **Apple Pay not available**
   - Verify merchant ID is configured correctly
   - Check Apple Pay entitlement in app
   - Ensure device supports Apple Pay

### Debug Logging

Enable debug logging in PaymentService:

```swift
// In PaymentService.swift
init() {
    #if DEBUG
    STPAPIClient.shared.logLevel = .debug
    #endif
}
```

## Migration from StoreKit

If you're migrating from StoreKit in-app purchases:

1. Existing subscriptions should remain in StoreKit
2. New subscriptions should use Stripe
3. Update app to handle both types during transition period
4. Eventually migrate all subscriptions to Stripe

## Support

For payment-related issues:
- Stripe Documentation: https://stripe.com/docs
- Stripe Support: https://support.stripe.com
- Modaics Team: payments@modaics.com

## License

This payment integration is proprietary to Modaics and should not be shared or used outside the organization.
