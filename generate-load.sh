#!/bin/bash
# Simple load generator for testing OpenTelemetry + Grafana

# Configuration
BACKEND_IP="10.10.1.4"  # Change to your backend VM internal IP
BASE_URL="http://$BACKEND_IP:8000"
DURATION=300  # Run for 5 minutes (300 seconds)
REQUESTS_PER_SECOND=10  # Increased from 2 to 10!

echo "🚀 Starting load generation..."
echo "📍 Target: $BASE_URL"
echo "⏱️  Duration: ${DURATION}s"
echo "📊 Rate: ${REQUESTS_PER_SECOND} req/s"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Press Ctrl+C to stop"
echo ""

START_TIME=$(date +%s)
TOTAL_REQUESTS=0
SUCCESS=0
ERRORS=0ip

# Function to make requests
make_requests() {
    # Generate random number once
    RAND=$((RANDOM % 100))
    
    # 80% generes (database query)
    if [ $RAND -lt 80 ]; then
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/generes" 2>/dev/null)
        ENDPOINT="generes"
    # 15% health checks (fast)
    elif [ $RAND -lt 95 ]; then
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health" 2>/dev/null)
        ENDPOINT="health"
    # 5% non-existent (generate 404 errors)
    else
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/nonexistent" 2>/dev/null)
        ENDPOINT="nonexistent"
    fi
    
    TOTAL_REQUESTS=$((TOTAL_REQUESTS + 1))
    
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "404" ]; then
        SUCCESS=$((SUCCESS + 1))
        echo "✅ Request #$TOTAL_REQUESTS | $ENDPOINT | $RESPONSE"
    else
        ERRORS=$((ERRORS + 1))
        echo "❌ Request #$TOTAL_REQUESTS | $ENDPOINT | $RESPONSE"
    fi
}

# Main loop
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    # Stop after duration
    if [ $ELAPSED -ge $DURATION ]; then
        break
    fi
    
    # Make requests
    for i in $(seq 1 $REQUESTS_PER_SECOND); do
        make_requests &
    done
    
    # Wait 1 second
    sleep 1
    
    # Show stats every 10 seconds
    if [ $((TOTAL_REQUESTS % 20)) -eq 0 ]; then
        echo ""
        echo "📊 Stats: $TOTAL_REQUESTS total | $SUCCESS success | $ERRORS errors | ${ELAPSED}s elapsed"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
done

# Final stats
echo ""
echo "✅ Load generation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Final Stats:"
echo "   Total Requests: $TOTAL_REQUESTS"
echo "   Successful: $SUCCESS"
echo "   Errors: $ERRORS"
echo "   Duration: ${ELAPSED}s"
echo "   Avg Rate: $((TOTAL_REQUESTS / ELAPSED)) req/s"
echo ""
echo "🎨 Now check Grafana:"
echo "   - Traces in Tempo"
echo "   - Logs in Loki"
echo "   - Metrics in Mimir"
