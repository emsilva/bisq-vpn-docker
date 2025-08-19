#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "========================================="
echo -e "${BLUE}Bisq Version Update Script${NC}"
echo "========================================="
echo ""

# Function to get current version from Dockerfile
get_current_version() {
    grep "ENV BISQ_VERSION=" docker/bisq/Dockerfile | cut -d'=' -f2
}

# Function to get latest version from GitHub
get_latest_version() {
    curl -s https://api.github.com/repos/bisq-network/bisq/releases/latest | \
        grep '"tag_name":' | \
        sed -E 's/.*"v([^"]+)".*/\1/'
}

# Function to check if version is valid
check_version_exists() {
    local version=$1
    local url="https://github.com/bisq-network/bisq/releases/download/v${version}/Bisq-64bit-${version}.deb"
    
    if curl --head --silent --fail "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to update version in Dockerfile
update_dockerfile() {
    local new_version=$1
    sed -i "s/ENV BISQ_VERSION=.*/ENV BISQ_VERSION=${new_version}/" docker/bisq/Dockerfile
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Dockerfile updated to version ${new_version}"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to update Dockerfile"
        return 1
    fi
}

# Function to backup current data
backup_data() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    echo -e "${BLUE}Creating backup...${NC}"
    
    mkdir -p "$backup_dir"
    
    if [ -d "volumes/bisq-data" ]; then
        cp -r volumes/bisq-data "$backup_dir/"
        echo -e "${GREEN}✓${NC} Data backed up to $backup_dir"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} No data to backup (volumes/bisq-data not found)"
        return 1
    fi
}

# Function to show version info
show_version_info() {
    local version=$1
    echo -e "${BLUE}Fetching release notes for v${version}...${NC}"
    echo ""
    
    local release_info=$(curl -s "https://api.github.com/repos/bisq-network/bisq/releases/tags/v${version}")
    local release_date=$(echo "$release_info" | grep '"published_at":' | cut -d'"' -f4 | cut -d'T' -f1)
    local release_name=$(echo "$release_info" | grep '"name":' | head -1 | cut -d'"' -f4)
    
    echo -e "${CYAN}Release:${NC} $release_name"
    echo -e "${CYAN}Date:${NC} $release_date"
    echo -e "${CYAN}Download:${NC} https://github.com/bisq-network/bisq/releases/tag/v${version}"
    echo ""
    
    # Show first 5 lines of release notes
    echo -e "${CYAN}Release Notes Preview:${NC}"
    echo "$release_info" | grep -oP '"body":\s*".*"' | \
        sed 's/"body":\s*"//; s/"$//' | \
        sed 's/\\r\\n/\n/g' | \
        head -15
    echo ""
    echo -e "${YELLOW}View full release notes at:${NC}"
    echo "https://github.com/bisq-network/bisq/releases/tag/v${version}"
}

# Function to rebuild containers
rebuild_containers() {
    echo -e "${BLUE}Rebuilding Bisq container...${NC}"
    
    # Stop containers
    echo "Stopping containers..."
    docker compose down
    
    # Build new image
    echo "Building new Bisq image..."
    docker compose build --no-cache bisq
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Build successful"
        
        # Start containers
        echo "Starting containers..."
        docker compose up -d
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Containers started"
            echo ""
            echo -e "${GREEN}Success! Bisq has been updated and restarted.${NC}"
            echo "Access at: http://localhost:6080"
            return 0
        else
            echo -e "${RED}✗${NC} Failed to start containers"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} Build failed"
        return 1
    fi
}

# Main script
echo "Checking versions..."
echo ""

CURRENT_VERSION=$(get_current_version)
LATEST_VERSION=$(get_latest_version)

if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}Error: Could not determine current version${NC}"
    exit 1
fi

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Error: Could not fetch latest version from GitHub${NC}"
    echo "Please check your internet connection"
    exit 1
fi

echo -e "${CYAN}Current version:${NC} $CURRENT_VERSION"
echo -e "${CYAN}Latest version:${NC}  $LATEST_VERSION"
echo ""

# Compare versions
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GREEN}✓ You are already running the latest version!${NC}"
    echo ""
    echo "Options:"
    echo "1) Rebuild anyway (refresh installation)"
    echo "2) Exit"
    read -p "Choice [1-2]: " choice
    
    case $choice in
        1)
            rebuild_containers
            ;;
        *)
            echo "Exiting..."
            exit 0
            ;;
    esac
else
    # New version available
    echo -e "${YELLOW}⚠ New version available!${NC}"
    echo ""
    
    # Show version info
    show_version_info "$LATEST_VERSION"
    echo ""
    
    echo "Options:"
    echo "1) Update to latest version ($LATEST_VERSION)"
    echo "2) Enter a specific version"
    echo "3) Skip update"
    read -p "Choice [1-3]: " choice
    
    case $choice in
        1)
            # Update to latest
            TARGET_VERSION="$LATEST_VERSION"
            ;;
        2)
            # Custom version
            read -p "Enter version (e.g., 1.9.21): " TARGET_VERSION
            
            echo "Checking if version $TARGET_VERSION exists..."
            if check_version_exists "$TARGET_VERSION"; then
                echo -e "${GREEN}✓${NC} Version $TARGET_VERSION is available"
            else
                echo -e "${RED}✗${NC} Version $TARGET_VERSION not found or invalid"
                echo "Please check https://github.com/bisq-network/bisq/releases"
                exit 1
            fi
            ;;
        *)
            echo "Update skipped"
            exit 0
            ;;
    esac
    
    # Confirm update
    echo ""
    echo -e "${YELLOW}This will update Bisq from $CURRENT_VERSION to $TARGET_VERSION${NC}"
    echo ""
    echo "Do you want to:"
    echo "1) Backup data and update"
    echo "2) Update without backup (not recommended)"
    echo "3) Cancel"
    read -p "Choice [1-3]: " backup_choice
    
    case $backup_choice in
        1)
            backup_data
            ;;
        2)
            echo -e "${YELLOW}⚠ Proceeding without backup${NC}"
            ;;
        *)
            echo "Update cancelled"
            exit 0
            ;;
    esac
    
    # Update Dockerfile
    echo ""
    update_dockerfile "$TARGET_VERSION"
    
    if [ $? -eq 0 ]; then
        # Rebuild containers
        echo ""
        rebuild_containers
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "========================================="
            echo -e "${GREEN}✓ Update Complete!${NC}"
            echo "========================================="
            echo -e "Bisq updated from ${YELLOW}$CURRENT_VERSION${NC} to ${GREEN}$TARGET_VERSION${NC}"
            echo ""
            echo "Your data has been preserved in ./volumes/bisq-data/"
            if [ "$backup_choice" = "1" ]; then
                echo "Backup available in ./backups/"
            fi
        else
            echo ""
            echo -e "${RED}Update failed during rebuild${NC}"
            echo "You can try again with: docker compose up -d"
        fi
    else
        echo -e "${RED}Failed to update Dockerfile${NC}"
        exit 1
    fi
fi