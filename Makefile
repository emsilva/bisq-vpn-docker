# =============================================================================
# BISQ VPN CONTAINER MAKEFILE
# =============================================================================
# Common development and deployment tasks

.PHONY: help build up down logs clean test lint security-scan

# Default target
help: ## Show this help message
	@echo "Bisq VPN Container - Available commands:"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# DEVELOPMENT COMMANDS
# =============================================================================

build: ## Build the Bisq container
	docker compose build bisq

up: ## Start all containers
	docker compose up -d

down: ## Stop all containers
	docker compose down

logs: ## Show container logs
	docker compose logs -f

clean: ## Stop containers and remove volumes
	docker compose down -v
	docker system prune -f

# =============================================================================
# TESTING AND QUALITY ASSURANCE
# =============================================================================

test: ## Run basic container tests
	@echo "Running container tests..."
	docker compose build bisq
	docker run --rm -d --name bisq-test bisq-vpn-docker-bisq:latest
	sleep 10
	docker exec bisq-test ps aux | grep -E "(s6|vnc|xfce)" || exit 1
	docker stop bisq-test
	@echo "✅ Tests passed"

lint: ## Run linting on shell scripts and Dockerfile
	@echo "Running ShellCheck..."
	find scripts/ -name "*.sh" -type f -exec shellcheck {} \;
	@echo "Running Hadolint..."
	hadolint docker/bisq/Dockerfile
	@echo "✅ Linting completed"

security-scan: ## Run security scans
	@echo "Running Trivy security scan..."
	docker compose build bisq
	trivy image bisq-vpn-docker-bisq:latest
	@echo "Running filesystem scan..."
	trivy fs .
	@echo "✅ Security scan completed"

# =============================================================================
# SECRETS MANAGEMENT
# =============================================================================

# VPN secrets are now managed via .env environment variables
# Use docker-compose.novpn.yml for direct connection or regular docker-compose.yml with .env for VPN

# =============================================================================
# UTILITY COMMANDS
# =============================================================================

vpn-test: ## Test VPN connection
	./scripts/test-vpn.sh

update-bisq: ## Update Bisq to latest version
	./scripts/update-bisq.sh

status: ## Show container status
	./scripts/start-bisq-vpn.sh status

# =============================================================================
# PRODUCTION COMMANDS
# =============================================================================

prod-build: ## Build for production with multi-stage Dockerfile
	docker build -f docker/bisq/Dockerfile.multistage -t bisq-vpn:prod docker/bisq

prod-up: ## Start production containers with secrets
	@echo "Starting production containers..."
	@if [ ! -f .env ]; then \
		echo "❌ Environment file not found. Copy .env.example to .env first."; \
		exit 1; \
	fi
	docker compose up -d

# =============================================================================
# MAINTENANCE
# =============================================================================

backup: ## Backup Bisq data
	@echo "Creating backup..."
	mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	cp -r volumes/bisq-data backups/$(shell date +%Y%m%d_%H%M%S)/
	@echo "✅ Backup completed in backups/$(shell date +%Y%m%d_%H%M%S)/"

update-deps: ## Update all dependencies
	@echo "Updating dependencies..."
	docker compose pull
	@echo "✅ Dependencies updated"

health-check: ## Check container health
	@echo "Checking container health..."
	docker compose ps
	@if docker ps | grep -q gluetun; then \
		echo "✅ VPN container is running"; \
		docker exec gluetun wget -qO- https://ipinfo.io/ip 2>/dev/null | xargs echo "VPN IP:"; \
	else \
		echo "❌ VPN container is not running"; \
	fi
	@if docker ps | grep -q bisq; then \
		echo "✅ Bisq container is running"; \
	else \
		echo "❌ Bisq container is not running"; \
	fi