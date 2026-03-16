#!/bin/bash
# Test script - alternates between health and generes

BACKEND_IP="10.10.1.4"  # Change to your backend VM internal IP
COUNTER=0

echo "🧪 Testing both endpoints on http://$BACKEND_IP:8000"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    COUNTER=$((COUNTER + 1))
    
    # Call health
    echo "[$COUNTER] Calling /health..."
    curl -v http://$BACKEND_IP:8000/health
    echo ""
    
    sleep 2
    
    # Call generes
    echo "[$COUNTER] Calling /generes..."
    curl -v http://$BACKEND_IP:8000/generes
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    sleep 2
done
