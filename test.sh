#!/bin/bash

set -e

echo "🚀 Running Caddy Redirect Tests"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Function to cleanup containers
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    docker stop caddy-test 2>/dev/null || true
    docker rm caddy-test 2>/dev/null || true
    docker stop backend-test 2>/dev/null || true
    docker rm backend-test 2>/dev/null || true
}

# Trap to cleanup on exit
trap cleanup EXIT

echo -e "\n${YELLOW}1. Testing Caddyfile validation...${NC}"
if docker run --rm -v "$(pwd)":/config caddy:2-alpine caddy validate --config /config/Caddyfile; then
    print_status 0 "Caddyfile syntax is valid"
else
    print_status 1 "Caddyfile syntax is invalid"
    exit 1
fi

echo -e "\n${YELLOW}2. Testing Docker build...${NC}"
if docker build -t caddy-redirect:test .; then
    print_status 0 "Docker build successful"
else
    print_status 1 "Docker build failed"
    exit 1
fi

echo -e "\n${YELLOW}3. Testing basic container startup...${NC}"
if docker run -d --name caddy-test \
    -p 8080:80 \
    -e CADDY_DOMAIN=localhost \
    -e CADDY_UPSTREAM=http://httpbin.org \
    caddy-redirect:test; then
    print_status 0 "Container started successfully"
else
    print_status 1 "Container failed to start"
    exit 1
fi

echo -e "\n${YELLOW}4. Testing HTTP connectivity...${NC}"
sleep 3
if curl -f -s --max-time 10 http://localhost:8080/get > /dev/null; then
    print_status 0 "HTTP request to proxy successful"
else
    print_status 1 "HTTP request to proxy failed"
    docker logs caddy-test
    exit 1
fi

echo -e "\n${YELLOW}5. Testing environment variable configuration...${NC}"
# Test custom domain
if docker run --rm \
    -e CADDY_DOMAIN=test.example.com \
    -e CADDY_UPSTREAM=http://backend:3000 \
    caddy-redirect:test \
    caddy list-configs 2>/dev/null | grep -q "test.example.com"; then
    print_status 0 "Environment variables properly configured"
else
    print_status 1 "Environment variables not properly configured"
    exit 1
fi

echo -e "\n${YELLOW}6. Testing with custom backend...${NC}"
# Start a simple backend server
docker run -d --name backend-test \
    -p 3000:80 \
    nginx:alpine

sleep 2

# Test proxy to custom backend
if docker run -d --name caddy-custom-test \
    -p 8081:80 \
    -e CADDY_DOMAIN=localhost \
    -e CADDY_UPSTREAM=http://host.docker.internal:3000 \
    caddy-redirect:test; then
    sleep 3
    if curl -f -s --max-time 10 http://localhost:8081 > /dev/null; then
        print_status 0 "Custom backend proxy works"
        docker stop caddy-custom-test
        docker rm caddy-custom-test
    else
        print_status 1 "Custom backend proxy failed"
        docker logs caddy-custom-test
        docker stop caddy-custom-test
        docker rm caddy-custom-test
        exit 1
    fi
else
    print_status 1 "Custom backend container failed to start"
    exit 1
fi

echo -e "\n${GREEN}🎉 All tests passed!${NC}"
echo -e "\nTo run individual tests:"
echo "  ./test.sh"
echo -e "\nTo run tests in GitHub Actions:"
echo "  Push to main branch or create a PR"
