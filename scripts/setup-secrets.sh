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
echo -e "${BLUE}VPN Secrets Setup Script${NC}"
echo "========================================="
echo ""

# Function to validate input
validate_input() {
    local input="$1"
    local field_name="$2"
    
    if [ -z "$input" ]; then
        echo -e "${RED}Error: $field_name cannot be empty${NC}"
        return 1
    fi
    
    # Basic validation for key format (base64-ish)
    if [[ ! "$input" =~ ^[A-Za-z0-9+/=]+$ ]]; then
        echo -e "${YELLOW}Warning: $field_name doesn't look like a valid key format${NC}"
        read -p "Continue anyway? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            return 1
        fi
    fi
    
    return 0
}

# Check if .env exists and extract current values
if [ -f ".env" ]; then
    echo -e "${BLUE}Found existing .env file${NC}"
    
    CURRENT_PRIVATE_KEY=$(grep "^WIREGUARD_PRIVATE_KEY=" .env | cut -d'=' -f2)
    CURRENT_PRESHARED_KEY=$(grep "^WIREGUARD_PRESHARED_KEY=" .env | cut -d'=' -f2)
    
    if [ -n "$CURRENT_PRIVATE_KEY" ] && [ -n "$CURRENT_PRESHARED_KEY" ]; then
        echo "Found existing VPN credentials in .env"
        echo ""
        echo "Options:"
        echo "1) Migrate existing credentials to secrets"
        echo "2) Enter new credentials"
        echo "3) Exit"
        read -p "Choice [1-3]: " choice
        
        case $choice in
            1)
                PRIVATE_KEY="$CURRENT_PRIVATE_KEY"
                PRESHARED_KEY="$CURRENT_PRESHARED_KEY"
                echo -e "${GREEN}Using existing credentials${NC}"
                ;;
            2)
                echo "Enter new credentials:"
                ;;
            *)
                echo "Exiting..."
                exit 0
                ;;
        esac
    fi
fi

# Get credentials if not already set
if [ -z "${PRIVATE_KEY:-}" ]; then
    echo ""
    echo "Enter your WireGuard credentials:"
    echo "--------------------------------"
    
    while true; do
        read -p "Private Key: " PRIVATE_KEY
        if validate_input "$PRIVATE_KEY" "Private Key"; then
            break
        fi
    done
    
    while true; do
        read -p "Preshared Key (optional): " PRESHARED_KEY
        if [ -z "$PRESHARED_KEY" ]; then
            echo -e "${YELLOW}No preshared key provided (optional)${NC}"
            break
        fi
        if validate_input "$PRESHARED_KEY" "Preshared Key"; then
            break
        fi
    done
fi

# Create secrets directory
echo ""
echo -e "${BLUE}Creating secrets directory...${NC}"
mkdir -p secrets

# Write secret files
echo -e "${BLUE}Writing secret files...${NC}"
echo "$PRIVATE_KEY" > secrets/wireguard_private_key.txt

if [ -n "$PRESHARED_KEY" ]; then
    echo "$PRESHARED_KEY" > secrets/wireguard_preshared_key.txt
else
    # Create empty file if no preshared key
    touch secrets/wireguard_preshared_key.txt
fi

# Secure the files
echo -e "${BLUE}Securing file permissions...${NC}"
chmod 600 secrets/wireguard_private_key.txt
chmod 600 secrets/wireguard_preshared_key.txt

# Update .env to remove sensitive values
if [ -f ".env" ]; then
    echo -e "${BLUE}Updating .env file...${NC}"
    
    # Create backup
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    
    # Remove sensitive keys from .env
    sed -i '/^WIREGUARD_PRIVATE_KEY=/d' .env
    sed -i '/^WIREGUARD_PRESHARED_KEY=/d' .env
    
    # Add comment about secrets
    if ! grep -q "# VPN secrets are now managed via Docker secrets" .env; then
        echo "" >> .env
        echo "# VPN secrets are now managed via Docker secrets" >> .env
        echo "# Use: docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d" >> .env
    fi
    
    echo -e "${GREEN}✓ .env updated (backup created)${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}✓ Secrets setup complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Verify secrets are created:"
echo "   ls -la secrets/"
echo ""
echo "2. Start containers with secrets:"
echo "   docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d"
echo ""
echo "3. For production, consider external secret management:"
echo "   - HashiCorp Vault"
echo "   - AWS Secrets Manager"
echo "   - Azure Key Vault"
echo ""
echo -e "${YELLOW}Important: Never commit the secrets/ directory to version control!${NC}"