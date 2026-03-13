#!/bin/bash
# Simple load generator - stops after N requests

BACKEND_IP="10.10.1.4"  # Change to your backend VM internal IP
MAX_REQUESTS=100         # Stop after this many requests

echo "🚀 Generating $MAX_REQUESTS requests to http://$BACKEND_IP:8000"
echo ""

for i in $(seq 1 $MAX_REQUESTS); do
    curl -s http://$BACKEND_IP:8000/health > /dev/null && echo "✅ $i: health OK"
    curl -s http://$BACKEND_IP:8000/generes > /dev/null && echo "✅ $i: generes OK"
    sleep 1
done

echo ""
echo "✅ Done! Generated $MAX_REQUESTS requests"
