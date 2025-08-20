# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based solution that runs Bisq (a decentralized Bitcoin exchange) through a VPN connection using WireGuard. The project uses two containers: Gluetun (VPN) and Bisq (application with VNC/noVNC access).

## Key Architecture Components

### Container Network Architecture
- **Gluetun container**: Provides VPN connectivity via WireGuard protocol
- **Bisq container**: Uses Gluetun's network stack (`network_mode: "service:gluetun"`)
- All Bisq traffic routes through VPN with kill switch protection
- Bisq uses Tor for P2P connectivity (requires unrestricted outbound firewall)

### VNC/noVNC Setup
- TigerVNC server (Xtigervnc) with `-AcceptSetDesktopSize=on` for dynamic resizing
- noVNC web interface on port 6080 with custom index.html (`resize=remote` parameter)
- Clipboard synchronization via `vncconfig` and `autocutsel`
- Monitor script (`docker/bisq/config/monitor-resize.sh`) watches for resolution changes and resizes Bisq window

### Process Management
- Supervisord manages all processes within Bisq container
- Process startup order: vnc → xstartup → novnc → bisq → resize-monitor
- XFCE desktop environment with panel and screensaver disabled

## Common Development Commands

### Building and Running
```bash
# Full rebuild with no cache
docker compose build --no-cache bisq

# Start all containers
docker compose up -d

# Stop and remove containers with volumes
docker compose down -v

# Rebuild just Bisq container
docker compose build bisq
```

### Testing and Debugging
```bash
# Check VPN connection
docker exec gluetun wget -qO- https://ipinfo.io/ip

# Access container shell
docker exec -it bisq bash

# Check running processes
docker exec bisq ps aux | grep -E "Xtigervnc|vncconfig|autocutsel|Bisq|monitor-resize"

# View logs
docker logs bisq --tail 50
docker exec bisq cat /var/log/supervisor/bisq.log

# Test clipboard tools
docker exec bisq bash -c 'DISPLAY=:1 vncconfig -nowin &'
docker exec bisq bash -c 'DISPLAY=:1 autocutsel -fork'

# Check VNC resolution
docker exec bisq bash -c 'DISPLAY=:1 xrandr | grep "^VNC-0"'

# Check Bisq window geometry
docker exec bisq bash -c 'DISPLAY=:1 wmctrl -l -G | grep -i bisq'
```

### Version Management
```bash
# Update Bisq to latest version
./scripts/update-bisq.sh

# Current version is in docker/bisq/Dockerfile:
# ENV BISQ_VERSION=1.9.21
```

## Critical Configuration Details

### WireGuard VPN Configuration
- Configuration provided via environment variables in .env file
- Endpoint IP must be resolved to IP address (not hostname) in docker-compose.yml
- IPv6 addresses must be removed from WIREGUARD_ADDRESSES
- Kill switch enabled by default

### Bisq Data Persistence
- **volumes/bisq-data**: Contains wallet, trade history, tor hidden service (CRITICAL - contains funds)
- **volumes/bisq-config**: XFCE and application settings
- **volumes/bisq-home**: Additional Bisq configuration

### Access Credentials
- Web interface: http://localhost:6080
- VNC direct: localhost:5901
- Password: `bisqvnc`

## Key Implementation Details

### Dynamic Window Resizing
The `docker/bisq/config/monitor-resize.sh` script runs continuously to detect VNC resolution changes and automatically resizes the Bisq window to fullscreen. This is necessary because Java Swing applications don't naturally follow desktop resizes.

### Clipboard Synchronization
Requires both `vncconfig -nowin` and `autocutsel` running to sync clipboard between host and container. The xstartup script starts these after the desktop environment is ready.

### Tor Connectivity
Bisq requires Tor for P2P network connectivity. The firewall configuration must NOT restrict outbound connections (`FIREWALL_OUTBOUND_SUBNETS` removed from Gluetun config).

### X Server Startup Timing
The xstartup script must wait for X server readiness before starting clipboard tools. The script uses `xset q` in a loop to detect when X is ready.

## Common Issues and Solutions

### VPN Not Connecting
- Verify WireGuard endpoint IP is correct in docker-compose.yml
- Check DNS resolution works: `docker exec gluetun nslookup google.com`
- Review Gluetun logs: `docker logs gluetun`

### Bisq Window Not Resizing
- Ensure monitor-resize.sh is running: `docker exec bisq ps aux | grep monitor-resize`
- Check resize monitor logs: `docker exec bisq cat /var/log/supervisor/resize-monitor.log`
- Manually trigger fullscreen: `docker exec bisq bash -c 'DISPLAY=:1 wmctrl -r "Bisq" -b add,fullscreen'`

### Clipboard Not Working
- Verify clipboard tools running: `docker exec bisq ps aux | grep -E "vncconfig|autocutsel"`
- Restart clipboard tools manually if needed (see Testing and Debugging commands above)

## File Modification Notes

When modifying key files:
- **docker/bisq/Dockerfile**: After changes, rebuild with `docker compose build --no-cache bisq`
- **docker/bisq/config/supervisord.conf**: Copy to container with `docker cp` or rebuild
- **docker/bisq/config/monitor-resize.sh**: Must be executable (`chmod +x`)
- **docker-compose.yml**: Remove `version` attribute (obsolete warning)