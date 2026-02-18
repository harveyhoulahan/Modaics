# Modaics Deployment Guide

Complete guide for building, deploying, and distributing the Modaics app.

---

## 📋 Pre-Deployment Checklist

Before deploying, ensure:

- [ ] All environment variables configured
- [ ] Database migrations run
- [ ] API keys validated
- [ ] Tests passing (backend + iOS)
- [ ] Design system fully implemented
- [ ] Payment webhooks configured
- [ ] Firebase security rules updated
- [ ] App Store metadata prepared
- [ ] Privacy policy updated
- [ ] Terms of service current

---

## 🔧 Environment Variables

### Backend (.env)

Create `.env` file in `backend/` directory:

```bash
# Required: OpenAI for AI Analysis
OPENAI_API_KEY=sk-proj-your-key-here

# Required: Database
DATABASE_URL=postgresql://postgres:password@host:5432/modaics

# Required: Stripe Payments
STRIPE_SECRET_KEY=sk_live_your_secret_key
STRIPE_PUBLISHABLE_KEY=pk_live_your_publishable_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Optional: Stripe Connect (for marketplace)
STRIPE_CONNECT_CLIENT_ID=ca_your_client_id

# Payment Configuration
PLATFORM_FEE_PERCENT=10.0
BUYER_FEE_DOMESTIC=6.0
BUYER_FEE_INTERNATIONAL=3.0
P2P_TRANSFER_FEE=2.0

# Apple Pay
APPLE_PAY_MERCHANT_ID=merchant.com.modaics.app

# Firebase (for backend verification)
FIREBASE_PROJECT_ID=modaics-production
FIREBASE_ADMIN_CREDENTIALS_PATH=/path/to/serviceAccount.json

# Optional: Monitoring
SENTRY_DSN=https://your-sentry-dsn
DATADOG_API_KEY=your-datadog-key

# Optional: Email
SENDGRID_API_KEY=SG.your-sendgrid-key
```

### iOS (xcconfig)

Create `Config.xcconfig`:

```
// API Configuration
BACKEND_URL = https:/$()/api.modaics.com
WEBSOCKET_URL = wss:/$()/api.modaics.com/ws

// Stripe
STRIPE_PUBLISHABLE_KEY = pk_live_your_publishable_key

// Feature Flags
ENABLE_AI_ANALYSIS = YES
ENABLE_PAYMENTS = YES
ENABLE_SKETCHBOOKS = YES
```

---

## 🚀 Backend Deployment

### Option 1: Docker Deployment (Recommended)

#### 1. Build Docker Image

```bash
cd backend

# Build image
docker build -t modaics-backend:latest .

# Tag for registry
docker tag modaics-backend:latest registry.digitalocean.com/modaics/backend:latest
```

#### 2. Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Expose port
EXPOSE 8000

# Run with gunicorn
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "app:app", "--bind", "0.0.0.0:8000"]
```

#### 3. Docker Compose (Production)

```yaml
version: '3.8'

services:
  api:
    image: modaics-backend:latest
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
    env_file:
      - .env
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 4G
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - api
    restart: unless-stopped
```

### Option 2: Cloud Platform Deployment

#### AWS (ECS/Fargate)

```bash
# 1. Push to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin your-account.dkr.ecr.region.amazonaws.com
docker tag modaics-backend:latest your-account.dkr.ecr.region.amazonaws.com/modaics-backend:latest
docker push your-account.dkr.ecr.region.amazonaws.com/modaics-backend:latest

# 2. Update ECS service
aws ecs update-service --cluster modaics-production --service api --force-new-deployment
```

#### Google Cloud Run

```bash
# Deploy to Cloud Run
gcloud run deploy modaics-api \
  --image gcr.io/your-project/modaics-backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "OPENAI_API_KEY=${OPENAI_API_KEY}" \
  --set-env-vars "DATABASE_URL=${DATABASE_URL}"
```

#### Heroku

```bash
# Deploy to Heroku
git push heroku main

# Set config vars
heroku config:set OPENAI_API_KEY=sk-proj-...
heroku config:set STRIPE_SECRET_KEY=sk_live_...
```

### Database Migration

```bash
# Run migrations before deploying new version
cd backend

# Local
python migrations/001_create_payment_tables.py

# Production (using connection string)
DATABASE_URL="your-production-db-url" python migrations/001_create_payment_tables.py
```

### SSL/TLS Configuration

#### Let's Encrypt (Certbot)

```bash
# Install certbot
sudo apt-get install certbot

# Generate certificates
sudo certbot certonly --standalone -d api.modaics.com

# Auto-renewal (add to crontab)
0 12 * * * /usr/bin/certbot renew --quiet
```

#### Nginx Configuration

```nginx
server {
    listen 80;
    server_name api.modaics.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.modaics.com;

    ssl_certificate /etc/letsencrypt/live/api.modaics.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.modaics.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /webhooks/stripe {
        proxy_pass http://localhost:8000/webhooks/stripe;
        # Stripe requires raw body for signature verification
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 📱 iOS App Store Submission

### 1. Pre-Build Checklist

```bash
# Update version numbers
# - In Xcode: Project → General → Version
# - In Info.plist: CFBundleShortVersionString

# Verify signing
# - Project → Signing & Capabilities
# - Ensure valid certificate and provisioning profile

# Run tests
cd ModaicsAppTemp
xcodebuild test -scheme ModaicsAppTemp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### 2. Build for Release

#### Using Xcode

```bash
# Archive for App Store
xcodebuild archive \
  -workspace ModaicsAppTemp.xcworkspace \
  -scheme ModaicsAppTemp \
  -destination 'generic/platform=iOS' \
  -archivePath build/Modaics.xcarchive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/Modaics.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath build/
```

#### exportOptions.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### 3. App Store Connect Setup

#### Required Assets

| Asset | Specifications |
|-------|---------------|
| App Icon | 1024×1024px PNG, no transparency |
| Screenshots | iPhone: 6.5" (1290×2796), 5.5" (1242×2208) |
| Preview Video | Optional, 15-30 seconds |
| App Preview | Auto-generated from screenshots |

#### App Information

```
App Name: Modaics - Sustainable Fashion
Subtitle: Discover Pre-Loved Luxury
Primary Category: Shopping
Secondary Category: Lifestyle

Keywords: sustainable fashion, vintage clothing, luxury resale, eco-friendly, pre-owned, designer, thrift, secondhand
```

### 4. App Review Information

```
Contact Information:
- First Name: [Your Name]
- Last Name: [Your Last Name]
- Phone: +1-xxx-xxx-xxxx
- Email: support@modaics.com

Demo Account:
- Username: demo@modaics.com
- Password: Demo123!

Notes for Reviewer:
Modaics is a sustainable fashion marketplace. Users can:
- List items using AI-powered image analysis
- Browse and search for pre-loved fashion
- Make secure purchases via Stripe
- Join brand sketchbooks for exclusive content

Test credit card for purchases: 4242 4242 4242 4242
Any future expiry date, any 3-digit CVC
```

### 5. Privacy & Compliance

#### App Privacy Details

```
Data Collection:
✓ Email Address (App Functionality, Account Management)
✓ Photos (App Functionality, Item Listings)
✓ Location (Optional, Local pickup features)
✓ Payment Info (Via Stripe, not stored on device)

Data Usage:
- Email: Account authentication, notifications
- Photos: Item listings, AI analysis
- Location: Local pickup coordination
- Purchase History: Transaction records

Third-Party Sharing:
- Stripe: Payment processing
- Firebase: Authentication, analytics
- OpenAI: Image analysis (opt-in)
```

#### Required Capability Declarations

```xml
<!-- Info.plist additions -->
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to take photos of items you want to sell.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to select images for your listings.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to show nearby pickup options.</string>

<key>NSFaceIDUsageDescription</key>
<string>Face ID is used for secure authentication.</string>
```

### 6. Submit for Review

```bash
# Using altool (command line)
xcrun altool --upload-app \
  --type ios \
  --file build/Modaics.ipa \
  --apiKey your-api-key \
  --apiIssuer your-issuer-id

# Or use Transporter app (GUI)
# Drag IPA to Transporter and click Deliver
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Run tests
        run: |
          pip install -r backend/requirements.txt
          pytest backend/tests
      
      - name: Build and push Docker
        run: |
          docker build -t modaics/backend:${{ github.sha }} backend/
          docker push modaics/backend:${{ github.sha }}
      
      - name: Deploy to production
        run: |
          ssh deploy@server "docker pull modaics/backend:${{ github.sha }} && docker-compose up -d"

  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build app
        run: |
          cd ModaicsAppTemp
          xcodebuild build -scheme ModaicsAppTemp -destination 'generic/platform=iOS'
      
      - name: Run tests
        run: |
          cd ModaicsAppTemp
          xcodebuild test -scheme ModaicsAppTemp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
      
      - name: Upload to TestFlight
        if: github.ref == 'refs/heads/main'
        run: |
          cd ModaicsAppTemp
          fastlane beta
```

### Fastlane Configuration

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    scan(scheme: "ModaicsAppTemp")
  end

  desc "Submit to TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "ModaicsAppTemp")
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      notify_external_testers: false
    )
  end

  desc "Submit to App Store"
  lane :release do
    increment_version_number
    build_app(scheme: "ModaicsAppTemp")
    upload_to_app_store(
      force: true,
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: true
    )
  end
end
```

---

## 🛠️ Post-Deployment

### Monitoring

#### Backend Health Checks

```bash
# Set up health check endpoint monitoring
curl -f http://api.modaics.com/health || echo "ALERT: API is down"

# Database connection check
curl -f http://api.modaics.com/health/db || echo "ALERT: Database connection failed"
```

#### iOS Crash Reporting

```swift
// In AppDelegate or App init
import FirebaseCrashlytics

Crashlytics.crashlytics().setCustomValue(APIClient.shared.environment, forKey: "api_environment")
```

### Rollback Plan

```bash
# Backend rollback
docker pull modaics/backend:previous-version
docker-compose up -d

# iOS rollback
# Submit previous build to App Store as emergency update
fastlane release version:1.0.0
```

---

## 📊 Environment Summary

| Environment | Backend URL | iOS Bundle ID | Stripe Mode |
|-------------|-------------|---------------|-------------|
| Development | localhost:8000 | com.modaics.dev | Test |
| Staging | staging-api.modaics.com | com.modaics.staging | Test |
| Production | api.modaics.com | com.modaics.app | Live |

---

**Last Updated**: February 2025
