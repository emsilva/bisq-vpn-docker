#!/bin/bash

echo "========================================="
echo "VPN Connection Test Script"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if container is running
check_container() {
    if docker ps | grep -q gluetun; then
        echo -e "${GREEN}✓${NC} Gluetun container is running"
        return 0
    else
        echo -e "${RED}✗${NC} Gluetun container is not running"
        echo "Please start the container with: docker-compose up -d"
        exit 1
    fi
}

# Function to check VPN health
check_health() {
    echo -n "Checking VPN health status... "
    HEALTH=$(docker inspect gluetun --format='{{.State.Health.Status}}' 2>/dev/null)
    
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "${GREEN}Healthy${NC}"
        return 0
    elif [ "$HEALTH" = "starting" ]; then
        echo -e "${YELLOW}Starting (please wait)${NC}"
        return 1
    else
        echo -e "${RED}Unhealthy${NC}"
        return 1
    fi
}

# Function to get IP information
get_ip_info() {
    echo ""
    echo "Fetching IP information..."
    echo "----------------------------------------"
    
    # Get public IP through VPN
    echo -n "VPN IP Address: "
    VPN_IP=$(docker exec gluetun wget -qO- https://ipinfo.io/ip 2>/dev/null)
    if [ -z "$VPN_IP" ]; then
        echo -e "${RED}Failed to get IP${NC}"
        return 1
    else
        echo -e "${GREEN}$VPN_IP${NC}"
    fi
    
    # Get detailed IP information
    echo ""
    echo "Detailed IP Information:"
    docker exec gluetun wget -qO- https://ipinfo.io/json 2>/dev/null | python3 -m json.tool 2>/dev/null || \
        docker exec gluetun wget -qO- https://ipinfo.io/json 2>/dev/null | jq '.' 2>/dev/null || \
        docker exec gluetun wget -qO- https://ipinfo.io/json 2>/dev/null
    
    echo ""
    echo "----------------------------------------"
}

# Function to test DNS
test_dns() {
    echo ""
    echo "Testing DNS resolution..."
    echo "----------------------------------------"
    
    # Test DNS resolution
    if docker exec gluetun nslookup google.com &>/dev/null; then
        echo -e "${GREEN}✓${NC} DNS is working"
        
        # Show DNS servers being used
        echo ""
        echo "DNS Servers in use:"
        docker exec gluetun cat /etc/resolv.conf | grep nameserver
    else
        echo -e "${RED}✗${NC} DNS resolution failed"
    fi
    
    echo "----------------------------------------"
}

# Function to check for IP leaks
check_ip_leak() {
    echo ""
    echo "Checking for IP leaks..."
    echo "----------------------------------------"
    
    # Get leak test results
    LEAK_TEST=$(docker exec gluetun wget -qO- https://ipleak.net/json/ 2>/dev/null)
    
    if [ -n "$LEAK_TEST" ]; then
        echo "IP Leak Test Results:"
        echo "$LEAK_TEST" | python3 -c "
import json
import sys
data = json.load(sys.stdin)
print(f\"  Country: {data.get('country_name', 'Unknown')}\"
print(f\"  City: {data.get('city_name', 'Unknown')}\"
print(f\"  ISP: {data.get('isp_name', 'Unknown')}\"
print(f\"  VPN Detection: {'Yes' if data.get('vpn', False) else 'No'}\"
" 2>/dev/null || echo "$LEAK_TEST"
    else
        echo -e "${YELLOW}Could not perform leak test${NC}"
    fi
    
    echo "----------------------------------------"
}

# Function to test kill switch
test_kill_switch() {
    echo ""
    echo "Kill Switch Status:"
    echo "----------------------------------------"
    
    # Check kill switch configuration
    KILL_SWITCH=$(docker exec gluetun printenv KILL_SWITCH 2>/dev/null)
    
    if [ "$KILL_SWITCH" = "on" ]; then
        echo -e "${GREEN}✓${NC} Kill switch is ENABLED"
        echo "  All traffic will be blocked if VPN connection drops"
    else
        echo -e "${YELLOW}⚠${NC} Kill switch is DISABLED"
        echo "  Traffic may leak if VPN connection drops"
    fi
    
    echo "----------------------------------------"
}

# Main execution
echo "Starting VPN connection tests..."
echo ""

# Check if container is running
check_container

# Wait for container to be healthy
echo ""
echo "Waiting for VPN to establish connection..."
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if check_health; then
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "Waiting... (Attempt $ATTEMPT/$MAX_ATTEMPTS)"
        sleep 2
    fi
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}VPN failed to become healthy after $MAX_ATTEMPTS attempts${NC}"
    echo ""
    echo "Container logs:"
    docker logs --tail 50 gluetun
    exit 1
fi

# Run all tests
get_ip_info
test_dns
check_ip_leak
test_kill_switch

echo ""
echo "========================================="
echo -e "${GREEN}VPN Test Complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Verify the IP address shown above is from your VPN provider"
echo "2. Confirm the location matches your VPN server"
echo "3. If everything looks good, proceed with adding the Bisq container"