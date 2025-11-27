#!/bin/bash
# Modaics Docker Connection Test Script
# Tests all components of the Modaics/FindThisFit stack

echo "🔍 Modaics Docker Connection Test"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Database
echo "1️⃣  Testing PostgreSQL Database..."
if docker exec modaics-db pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database is running and healthy${NC}"
    
    # Check item count
    ITEM_COUNT=$(docker exec modaics-db psql -U postgres -d modaics -t -c "SELECT COUNT(*) FROM fashion_items;" 2>/dev/null | tr -d ' ')
    if [ ! -z "$ITEM_COUNT" ] && [ "$ITEM_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Database has $ITEM_COUNT fashion items${NC}"
    else
        echo -e "${YELLOW}⚠️  Database is empty or table doesn't exist${NC}"
    fi
else
    echo -e "${RED}❌ Database is not running${NC}"
fi
echo ""

# Test 2: Backend API
echo "2️⃣  Testing Backend API..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    HEALTH=$(curl -s http://localhost:8000/health)
    echo -e "${GREEN}✅ Backend API is running${NC}"
    echo "   Response: $HEALTH"
else
    echo -e "${RED}❌ Backend API is not responding on port 8000${NC}"
fi
echo ""

# Test 3: Docker containers
echo "3️⃣  Checking Docker Containers..."
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=modaics" --filter "name=findthisfit"
echo ""

# Test 4: API Endpoints
echo "4️⃣  Testing API Endpoints..."

# Health endpoint
if curl -s http://localhost:8000/health | grep -q "ok"; then
    echo -e "${GREEN}✅ /health endpoint working${NC}"
else
    echo -e "${RED}❌ /health endpoint failed${NC}"
fi

# Metrics endpoint
if curl -s http://localhost:8000/metrics > /dev/null 2>&1; then
    echo -e "${GREEN}✅ /metrics endpoint working${NC}"
else
    echo -e "${YELLOW}⚠️  /metrics endpoint not available${NC}"
fi
echo ""

# Test 5: Network connectivity
echo "5️⃣  Testing Network Connectivity..."
# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null)
if [ ! -z "$LOCAL_IP" ]; then
    echo "   Local IP Address: $LOCAL_IP"
    echo "   iOS App should connect to: http://$LOCAL_IP:8000"
    
    # Test if API is accessible from local network
    if curl -s --max-time 2 "http://$LOCAL_IP:8000/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API is accessible from local network${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not verify network accessibility${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not determine local IP address${NC}"
fi
echo ""

# Test 6: Database connection from API
echo "6️⃣  Testing API → Database Connection..."
METRICS=$(curl -s http://localhost:8000/metrics)
if echo "$METRICS" | grep -q "pool_size"; then
    echo -e "${GREEN}✅ API successfully connected to database${NC}"
    echo "   Metrics: $METRICS"
else
    echo -e "${YELLOW}⚠️  Could not verify database connection${NC}"
fi
echo ""

# Summary
echo "=================================="
echo "📊 Connection Summary"
echo "=================================="
echo "Database (modaics-db):     Port 5433 → 5432"
echo "Backend API (findthisfit): Port 8000 → 8000"
echo ""
echo "🎯 Next Steps:"
echo "1. Ensure your iOS app connects to http://$LOCAL_IP:8000"
echo "2. Update SearchAPIClient baseURL if needed"
echo "3. Test search functionality in the app"
echo ""
echo "✨ Run './test_connection.sh' anytime to verify connections"
