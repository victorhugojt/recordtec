#!/bin/bash
# Heavy load generator

BACKEND_IP="10.10.1.4"
REQUESTS_PER_SECOND=${1:-20}  # Default 20, or pass as argument

echo "🔥 Generating heavy load: $REQUESTS_PER_SECOND req/s"
echo "Press Ctrl+C to stop"

COUNTER=0
while true; do
  for i in $(seq 1 $REQUESTS_PER_SECOND); do
    # 80% generes, 20% health
    if [ $((RANDOM % 100)) -lt 80 ]; then
      curl -s http://$BACKEND_IP:8000/generes > /dev/null &
    else
      curl -s http://$BACKEND_IP:8000/health > /dev/null &
    fi
  done
  
  COUNTER=$((COUNTER + REQUESTS_PER_SECOND))
  echo "✅ Total: $COUNTER requests"
  sleep 1
done
