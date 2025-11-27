#!/bin/bash
# Quick Modaics Docker Status Check

echo "📊 Modaics Quick Status"
echo "======================="
echo ""

# Check containers
echo "🐳 Containers:"
docker ps --format "{{.Names}}: {{.Status}}" --filter "name=modaics" --filter "name=findthisfit" | grep -E "(modaics|findthisfit)"

echo ""
echo "📡 API Health:"
curl -s http://localhost:8000/health | grep -o '"status":"[^"]*"' || echo "❌ API not responding"

echo ""
echo "💾 Database Items:"
docker exec modaics-db psql -U postgres -d modaics -t -c "SELECT COUNT(*) FROM fashion_items;" 2>/dev/null | tr -d ' ' | xargs -I {} echo "{} fashion items"

echo ""
echo "🌐 Your Local IP: $(ipconfig getifaddr en0 2>/dev/null || echo 'unknown')"
echo "📱 iOS App URL: http://$(ipconfig getifaddr en0 2>/dev/null || echo 'unknown'):8000"
echo ""
echo "✨ For full test: ./test_connection.sh"
