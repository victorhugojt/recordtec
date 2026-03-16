#!/bin/bash
# Very simple load generator - infinite loop until Ctrl+C

BACKEND_IP="10.10.1.4"  # Change to your backend VM internal IP
COUNTER=0

echo "🚀 Generating load on http://$BACKEND_IP:8000"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    COUNTER=$((COUNTER + 1))
    
    # Make request
    curl -s http://$BACKEND_IP:8000/health > /dev/null && echo "✅ $COUNTER: health OK"
    curl -s http://$BACKEND_IP:8000/generes > /dev/null && echo "✅ $COUNTER: generes OK"
    
    sleep 1
done
