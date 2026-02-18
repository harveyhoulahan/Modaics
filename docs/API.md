# Modaics API Documentation

Complete reference for the Modaics FastAPI backend endpoints.

**Base URL**: `https://api.modaics.com/v1` (production)  
**Base URL**: `http://localhost:8000` (local development)

---

## 🔐 Authentication

Most endpoints require authentication via Firebase ID token in the Authorization header:

```http
Authorization: Bearer <firebase_id_token>
```

### Getting a Firebase ID Token

```swift
// iOS (Swift)
import FirebaseAuth

let user = Auth.auth().currentUser
user?.getIDTokenResult(forcingRefresh: true) { result, error in
    guard let token = result?.token else { return }
    // Use token in API calls
}
```

### Auth Error Responses

| Status | Code | Description |
|--------|------|-------------|
| 401 | `UNAUTHORIZED` | Missing or invalid token |
| 403 | `FORBIDDEN` | Valid token but insufficient permissions |
| 401 | `TOKEN_EXPIRED` | Token has expired, refresh required |

---

## 📤 AI & Image Analysis

### Analyze Image

Analyzes a fashion item image using GPT-4 Vision and CLIP to extract attributes.

```http
POST /analyze_image
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "image": "base64_encoded_image_string"
}
```

**Response (200 OK):**
```json
{
  "detected_item": "Black Embroidered Casual Sneakers",
  "likely_brand": "Prada",
  "category": "shoes",
  "specific_category": "casual_sneakers",
  "estimated_size": "M",
  "estimated_condition": "excellent",
  "description": "Prada Black Embroidered Casual Sneakers, Size M, Excellent.",
  "colors": ["Black"],
  "pattern": "Embroidered",
  "materials": ["Leather", "Canvas"],
  "estimated_price": 450.00,
  "confidence": 0.85,
  "confidence_scores": {
    "category": 0.92,
    "colors": [0.85],
    "pattern": 0.78,
    "brand": 0.95
  }
}
```

**Error Responses:**
| Status | Code | Description |
|--------|------|-------------|
| 400 | `INVALID_IMAGE` | Base64 decode failed or invalid image format |
| 500 | `EMBEDDING_ERROR` | CLIP model failed to process image |
| 500 | `ANALYSIS_ERROR` | GPT-4 Vision API error |

---

### Generate Description

Generates a professional product description using GPT-4 Vision.

```http
POST /generate_description
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "image": "base64_encoded_image_string",
  "category": "jacket",
  "brand": "Prada",
  "colors": ["Black"],
  "condition": "excellent",
  "materials": ["Leather"],
  "size": "M"
}
```

**Response (200 OK):**
```json
{
  "description": "Navy windbreaker jacket in excellent condition. Features zip closure and side pockets.",
  "method": "gpt4_vision",
  "confidence": 0.95
}
```

---

## 🔍 Search

### Search by Image

Find visually similar items using an image.

```http
POST /search_by_image
Content-Type: application/json
```

**Request Body:**
```json
{
  "image_base64": "base64_encoded_image_string",
  "limit": 20
}
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": 12345,
      "external_id": "depop_987654",
      "title": "Vintage Leather Jacket",
      "description": "Genuine leather, great condition",
      "price": 89.99,
      "url": "https://depop.com/listing/987654",
      "image_url": "https://depop.com/images/987654.jpg",
      "distance": 0.23,
      "redirect_url": "https://depop.app/...",
      "source": "depop",
      "brand": "Vintage",
      "category": "outerwear",
      "size": "M",
      "condition": "good"
    }
  ]
}
```

---

### Search by Text

Find items using text description.

```http
POST /search_by_text
Content-Type: application/json
```

**Request Body:**
```json
{
  "query": "vintage black leather jacket",
  "limit": 20,
  "filters": {
    "min_price": 50,
    "max_price": 200,
    "category": "outerwear",
    "brand": "Vintage",
    "size": "M"
  }
}
```

**Response (200 OK):**
Same format as `/search_by_image`

---

### Combined Search

Search using both image and text for most accurate results.

```http
POST /search_combined
Content-Type: application/json
```

**Request Body:**
```json
{
  "query": "vintage distressed denim",
  "image_base64": "base64_encoded_image_string",
  "limit": 20
}
```

**Response (200 OK):**
Same format as `/search_by_image`

---

## 👕 Items

### Add Item

Add a new fashion item to the database with CLIP embeddings.

```http
POST /add_item
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "image_base64": "base64_encoded_image_string",
  "title": "Vintage Prada Nylon Bag",
  "description": "Authentic vintage Prada bag in excellent condition",
  "price": 350.00,
  "brand": "Prada",
  "category": "bags",
  "size": "One Size",
  "condition": "excellent",
  "owner_id": "user_123",
  "source": "modaics",
  "image_url": "https://cdn.modaics.com/images/..."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "item_id": "item_98765",
  "message": "Item added successfully with CLIP embeddings"
}
```

---

### Get Item

Retrieve a specific item by ID.

```http
GET /items/{item_id}
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "id": "item_98765",
  "title": "Vintage Prada Nylon Bag",
  "description": "Authentic vintage Prada bag...",
  "price": 350.00,
  "brand": "Prada",
  "category": "bags",
  "size": "One Size",
  "condition": "excellent",
  "colors": ["Black"],
  "materials": ["Nylon", "Leather"],
  "sustainability_score": 85,
  "owner_id": "user_123",
  "image_url": "https://cdn.modaics.com/images/...",
  "created_at": "2024-01-15T10:30:00Z",
  "status": "active"
}
```

---

### Get Similar Items

Get items similar to a specific item.

```http
GET /items/{item_id}/similar?limit=10
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "item_98766",
      "title": "Prada Nylon Tote",
      "price": 295.00,
      "image_url": "...",
      "similarity_score": 0.92
    }
  ]
}
```

---

## 💳 Payments

### Create Item Purchase Intent

Create a Stripe PaymentIntent for buying an item.

```http
POST /payments/item-purchase
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "item_id": "item_98765",
  "seller_id": "user_456",
  "amount": 350.00,
  "currency": "usd",
  "buyer_fee": 21.00,
  "total_amount": 371.00,
  "is_international": false,
  "shipping_address": {
    "name": "John Doe",
    "line1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001",
    "country": "US"
  }
}
```

**Response (200 OK):**
```json
{
  "client_secret": "pi_123_secret_456",
  "payment_intent_id": "pi_1234567890",
  "ephemeral_key": "ek_1234567890",
  "customer_id": "cus_1234567890",
  "publishable_key": "pk_live_...",
  "amount": 371.00,
  "currency": "usd",
  "status": "requires_confirmation"
}
```

---

### Create Subscription Intent

Create a payment intent for brand subscription.

```http
POST /payments/subscription
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "plan_id": "price_pro_monthly",
  "brand_id": "brand_123",
  "tier": "pro"
}
```

**Response (200 OK):**
Same format as item purchase intent

---

### Create P2P Transfer

Create a payment intent for peer-to-peer money transfer.

```http
POST /payments/p2p-transfer
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "amount": 100.00,
  "currency": "usd",
  "recipient_id": "user_789",
  "note": "Thanks for the jacket!"
}
```

**Response (200 OK):**
Same format as item purchase intent

---

### Confirm Payment

Confirm a payment after Stripe processing.

```http
POST /payments/confirm
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "payment_intent_id": "pi_1234567890"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "transaction_id": "txn_123456",
  "status": "completed",
  "amount": 371.00,
  "seller_amount": 315.00,
  "platform_fee": 35.00,
  "buyer_fee": 21.00
}
```

---

### Calculate Fees

Calculate fees for a transaction without creating a payment.

```http
POST /payments/calculate-fees
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 100.00,
  "is_international": false,
  "type": "item_purchase"
}
```

**Response (200 OK):**
```json
{
  "item_price": 100.00,
  "buyer_fee": 6.00,
  "platform_fee": 10.00,
  "seller_receives": 90.00,
  "total_charge": 106.00
}
```

---

## 📊 Transactions

### List User Transactions

Get transaction history for the authenticated user.

```http
GET /transactions?limit=50&offset=0
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "transactions": [
    {
      "id": "txn_123456",
      "buyer_id": "user_123",
      "seller_id": "user_456",
      "item_id": "item_98765",
      "amount": 371.00,
      "currency": "USD",
      "platform_fee": 35.00,
      "seller_amount": 315.00,
      "status": "completed",
      "type": "item_purchase",
      "description": "Purchase of item item_98765",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:31:00Z",
      "metadata": {
        "item_id": "item_98765",
        "original_price": 350.00,
        "buyer_fee": 21.00
      }
    }
  ],
  "total": 156,
  "offset": 0,
  "limit": 50
}
```

---

### Get Transaction Details

Get detailed information about a specific transaction.

```http
GET /transactions/{transaction_id}
Authorization: Bearer <token>
```

**Response (200 OK):**
Same format as transaction object above with additional `payment_method_details` and `receipt_url`.

---

### Request Refund

Request a refund for an eligible transaction.

```http
POST /transactions/{transaction_id}/refund
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "reason": "Item not as described",
  "amount": 371.00
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "refund_id": "re_123456",
  "amount_refunded": 371.00,
  "status": "pending",
  "estimated_arrival": "5-10 business days"
}
```

---

## 📚 Sketchbooks (Brand Pages)

### Get Brand Sketchbook

Get a brand's sketchbook page.

```http
GET /sketchbook/brand/{brand_id}
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "id": 123,
  "brand_id": "brand_123",
  "title": "Prada Collective",
  "description": "Exclusive access to Prada drops and vintage finds",
  "access_policy": "subscription",
  "membership_rule": "auto_approve",
  "min_spend_amount": null,
  "min_spend_window_months": null,
  "member_count": 15420,
  "is_member": true,
  "created_at": "2024-01-01T00:00:00Z"
}
```

---

### Update Sketchbook Settings

Update sketchbook settings (brand only).

```http
PUT /sketchbook/{sketchbook_id}/settings
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "title": "Prada Collective",
  "description": "Updated description",
  "access_policy": "subscription",
  "membership_rule": "min_spend",
  "min_spend_amount": 500.00,
  "min_spend_window_months": 12
}
```

---

### Get Sketchbook Posts

Get posts from a sketchbook.

```http
GET /sketchbook/{sketchbook_id}/posts?limit=50
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "posts": [
    {
      "id": 456,
      "post_type": "poll",
      "title": "Which vintage bag should we restock?",
      "body": "Vote for your favorite!",
      "media": ["https://cdn.modaics.com/..."],
      "author": {
        "id": "brand_123",
        "name": "Prada Official",
        "avatar_url": "https://cdn.modaics.com/..."
      },
      "poll": {
        "question": "Which vintage bag should we restock?",
        "options": ["Nylon 2000", "Galleria", "Cahier"],
        "votes": [450, 230, 180],
        "closes_at": "2024-02-01T00:00:00Z"
      },
      "created_at": "2024-01-15T10:00:00Z",
      "likes_count": 1250,
      "comments_count": 89
    }
  ]
}
```

---

### Create Sketchbook Post

Create a new post (brand only).

```http
POST /sketchbook/{sketchbook_id}/posts
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "author_user_id": "brand_123",
  "post_type": "poll",
  "title": "New Drop Preview",
  "body": "Check out our latest sustainable collection!",
  "media": ["base64_image_1", "base64_image_2"],
  "tags": ["sustainable", "new-drop"],
  "visibility": "public",
  "poll_question": "Which colorway?",
  "poll_options": ["Forest Green", "Midnight Black", "Cream"],
  "poll_closes_at": "2024-02-01T00:00:00Z"
}
```

---

### Delete Post

Delete a sketchbook post (author only).

```http
DELETE /sketchbook/posts/{post_id}?user_id={user_id}
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true
}
```

---

### Check Membership Status

Check if user has access to a sketchbook.

```http
GET /sketchbook/{sketchbook_id}/membership/{user_id}
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "status": "active",
  "joined_at": "2024-01-10T15:30:00Z",
  "tier": "pro",
  "expires_at": "2024-02-10T15:30:00Z"
}
```

---

### Request Membership

Join or request to join a sketchbook.

```http
POST /sketchbook/{sketchbook_id}/membership
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "user_id": "user_123",
  "join_source": "requestApproved"
}
```

**Response (200 OK):**
```json
{
  "status": "approved",
  "membership_id": "mem_123456",
  "joined_at": "2024-01-15T10:30:00Z"
}
```

---

## 🔔 Webhooks

### Stripe Webhook

Endpoint for Stripe webhook events.

```http
POST /webhooks/stripe
Content-Type: application/json
Stripe-Signature: {signature}
```

**Events Handled:**
- `payment_intent.succeeded` - Payment completed
- `payment_intent.payment_failed` - Payment failed
- `charge.refunded` - Refund processed
- `customer.subscription.created` - New subscription
- `customer.subscription.deleted` - Subscription cancelled

**Response (200 OK):**
```json
{
  "status": "success",
  "event_type": "payment_intent.succeeded"
}
```

---

## ❌ Error Codes

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required or failed |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource conflict (e.g., duplicate) |
| 422 | Unprocessable | Validation error |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Server Error | Internal server error |
| 503 | Service Unavailable | Temporary maintenance |

### Error Response Format

```json
{
  "error": {
    "code": "INVALID_IMAGE_FORMAT",
    "message": "The provided image is not a valid format. Supported formats: JPG, PNG, WEBP",
    "details": {
      "field": "image",
      "provided": "image/bmp"
    },
    "request_id": "req_1234567890"
  }
}
```

### Common Error Codes

| Code | Description | Resolution |
|------|-------------|------------|
| `INVALID_IMAGE` | Base64 decode failed | Check image encoding |
| `INVALID_IMAGE_FORMAT` | Unsupported image type | Use JPG, PNG, or WEBP |
| `IMAGE_TOO_LARGE` | Image exceeds 10MB limit | Compress image |
| `EMBEDDING_ERROR` | CLIP model error | Retry request |
| `AI_ANALYSIS_ERROR` | GPT-4 Vision error | Check OpenAI status |
| `ITEM_NOT_FOUND` | Item ID doesn't exist | Verify item ID |
| `INSUFFICIENT_FUNDS` | Payment failed | Check payment method |
| `ALREADY_PURCHASED` | Item already sold | Refresh listings |
| `SKETCHBOOK_ACCESS_DENIED` | Not a member | Subscribe or request access |
| `RATE_LIMIT_EXCEEDED` | Too many requests | Wait and retry |

---

## 📊 Rate Limits

| Endpoint Group | Limit | Window |
|----------------|-------|--------|
| Search (all) | 100 | per minute |
| AI Analysis | 20 | per minute |
| Payments | 30 | per minute |
| General API | 1000 | per hour |

Rate limit headers are included in responses:

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1640995200
```

---

## 🌐 Pagination

List endpoints support pagination with `limit` and `offset`:

```http
GET /transactions?limit=50&offset=100
```

Response includes pagination metadata:

```json
{
  "data": [...],
  "pagination": {
    "total": 256,
    "limit": 50,
    "offset": 100,
    "has_more": true,
    "next_offset": 150
  }
}
```

---

## 📱 SDK Examples

### iOS (Swift)

```swift
import Foundation

class ModaicsAPI {
    static let shared = ModaicsAPI()
    private let baseURL = "https://api.modaics.com/v1"
    
    func analyzeImage(base64Image: String, completion: @escaping (Result<ItemAnalysis, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/analyze_image") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        if let token = AuthManager.shared.idToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["image": base64Image]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle response
        }.resume()
    }
}
```

### Python

```python
import requests

class ModaicsClient:
    def __init__(self, base_url: str, token: str = None):
        self.base_url = base_url
        self.headers = {"Content-Type": "application/json"}
        if token:
            self.headers["Authorization"] = f"Bearer {token}"
    
    def analyze_image(self, image_base64: str) -> dict:
        response = requests.post(
            f"{self.base_url}/analyze_image",
            headers=self.headers,
            json={"image": image_base64}
        )
        response.raise_for_status()
        return response.json()
    
    def search_by_text(self, query: str, limit: int = 20) -> dict:
        response = requests.post(
            f"{self.base_url}/search_by_text",
            headers=self.headers,
            json={"query": query, "limit": limit}
        )
        response.raise_for_status()
        return response.json()
```

---

## 📖 Additional Resources

- [Postman Collection](./modaics-api-postman.json)
- [OpenAPI Spec](./openapi.yaml)
- [Webhook Testing Guide](./webhooks.md)

---

**API Version**: 1.0.0  
**Last Updated**: February 2025
