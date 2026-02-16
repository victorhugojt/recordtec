# Build
docker build -t recordtec:local .

# Run
docker run -d -p 8000:8000 --name recordtec-test recordtec:local

# Wait a moment for startup
sleep 3

# Test endpoints
echo "Testing health endpoint..."
curl http://localhost:8000/health

echo -e "\n\nTesting generes endpoint..."
curl http://localhost:8000/generes

# View logs
echo -e "\n\nContainer logs:"
docker logs recordtec-test