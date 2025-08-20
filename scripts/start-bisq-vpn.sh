#!/bin/bash

# Enable strict error handling  
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================="
echo -e "${BLUE}Bisq VPN Container Startup Script${NC}"
echo "========================================="
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  start    - Start Bisq with VPN"
    echo "  stop     - Stop all containers"
    echo "  restart  - Restart all containers"
    echo "  status   - Show container status"
    echo "  logs     - Show container logs"
    echo "  test     - Test VPN connection"
    echo "  build    - Rebuild Bisq container"
    echo "  clean    - Stop and remove all containers and volumes"
    echo ""
}

# Function to check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    if ! docker ps &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
}

# Function to start containers
start_containers() {
    echo -e "${BLUE}Starting Bisq VPN containers...${NC}"
    
    # Check if gluetun is already running
    if docker ps | grep -q gluetun; then
        echo -e "${YELLOW}VPN container is already running${NC}"
    else
        echo "Starting VPN container..."
        docker compose up -d gluetun
        
        echo "Waiting for VPN to establish connection..."
        sleep 10
        
        # Test VPN connection
        VPN_IP=$(docker exec gluetun wget -qO- https://ipinfo.io/ip 2>/dev/null)
        if [ -n "$VPN_IP" ]; then
            echo -e "${GREEN}✓ VPN connected: IP $VPN_IP${NC}"
        else
            echo -e "${RED}✗ VPN connection failed${NC}"
            echo "Check logs with: docker logs gluetun"
            exit 1
        fi
    fi
    
    # Build and start Bisq container
    echo "Building Bisq container..."
    docker compose build bisq
    
    echo "Starting Bisq container..."
    docker compose up -d bisq
    
    echo ""
    echo -e "${GREEN}✓ All containers started successfully!${NC}"
    echo ""
    echo "========================================="
    echo -e "${BLUE}Access Bisq:${NC}"
    echo "  Web Browser (noVNC): http://localhost:6080"
    echo "  VNC Client: localhost:5901"
    echo "  VNC Password: bisqvnc"
    echo ""
    echo -e "${YELLOW}Note: It may take a minute for Bisq to fully load${NC}"
    echo "========================================="
}

# Function to stop containers
stop_containers() {
    echo -e "${BLUE}Stopping all containers...${NC}"
    docker compose down
    echo -e "${GREEN}✓ Containers stopped${NC}"
}

# Function to restart containers
restart_containers() {
    stop_containers
    echo ""
    start_containers
}

# Function to show status
show_status() {
    echo -e "${BLUE}Container Status:${NC}"
    echo "----------------------------------------"
    docker compose ps
    echo ""
    
    # Check VPN connection
    if docker ps | grep -q gluetun; then
        echo -e "${BLUE}VPN Status:${NC}"
        VPN_IP=$(docker exec gluetun wget -qO- https://ipinfo.io/ip 2>/dev/null)
        if [ -n "$VPN_IP" ]; then
            echo -e "${GREEN}✓ Connected - IP: $VPN_IP${NC}"
            
            # Get location info
            LOCATION=$(docker exec gluetun wget -qO- https://ipinfo.io/json 2>/dev/null | grep -oP '"city":\s*"\K[^"]*' 2>/dev/null)
            COUNTRY=$(docker exec gluetun wget -qO- https://ipinfo.io/json 2>/dev/null | grep -oP '"country":\s*"\K[^"]*' 2>/dev/null)
            if [ -n "$LOCATION" ] && [ -n "$COUNTRY" ]; then
                echo "  Location: $LOCATION, $COUNTRY"
            fi
        else
            echo -e "${RED}✗ Not connected${NC}"
        fi
    else
        echo -e "${YELLOW}VPN container is not running${NC}"
    fi
    echo "----------------------------------------"
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}Container Logs:${NC}"
    echo "Select container:"
    echo "1) Gluetun (VPN)"
    echo "2) Bisq"
    echo "3) Both"
    read -p "Choice: " choice
    
    case $choice in
        1)
            docker logs --tail 50 -f gluetun
            ;;
        2)
            docker logs --tail 50 -f bisq
            ;;
        3)
            docker compose logs --tail 50 -f
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

# Function to test VPN
test_vpn() {
    if [ -f "./scripts/test-vpn.sh" ]; then
        ./scripts/test-vpn.sh
    else
        echo -e "${RED}Test script not found${NC}"
    fi
}

# Function to rebuild containers
build_containers() {
    echo -e "${BLUE}Rebuilding Bisq container...${NC}"
    docker compose build --no-cache bisq
    echo -e "${GREEN}✓ Build complete${NC}"
}

# Function to clean everything
clean_all() {
    echo -e "${RED}Warning: This will remove all containers and volumes!${NC}"
    read -p "Are you sure? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "Stopping and removing containers..."
        docker compose down -v
        echo "Removing Docker images..."
        docker rmi bisq-vpn-docker-bisq 2>/dev/null
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    else
        echo "Cancelled"
    fi
}

# Main script
check_docker

# Handle case where no argument provided
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    start)
        start_containers
        ;;
    stop)
        stop_containers
        ;;
    restart)
        restart_containers
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    test)
        test_vpn
        ;;
    build)
        build_containers
        ;;
    clean)
        clean_all
        ;;
    *)
        show_usage
        ;;
esac