# Bisq Docker Container

> Run Bisq in your browser because installing desktop apps is for peasants

[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)](https://www.docker.com/)
[![Bisq](https://img.shields.io/badge/Bisq-1.9.21-green)](https://bisq.network/)
[![VPN](https://img.shields.io/badge/VPN-WireGuard-orange)](https://www.wireguard.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

## ☕ Buy Me Coffee (If This Doesn't Suck)

If this actually works for you and saves you some pain:

**Bitcoin**: `bc1qkdjdfeev6rgkqsszam2qr8r9ytky80cdy8zu2x`  
**Ethereum**: `0x1963fa2E60606c7761Ea2242Ab00e0fBd096ba59`  
**Solana**: `MNibKyhZka5NMNvRYJUiAG3MXaCTkAE1hACLuCX9RYr`  
**Monero**: `48Q7CFnSjG4WGmYVusqnenggjEQSTw1QpJYuy7GaC1iifh8hZgUFmwi8cU84njepNVZRAjv6H687mBJgCYo5KBwW299BG9G`

---

## What This Actually Does

Look, I got tired of installing Bisq on every machine I use. So I containerized it and made it accessible through a web browser. Now you can trade Bitcoin from anywhere without dealing with desktop app nonsense. Perfect for home servers, remote machines, or just keeping your main system clean.

### The Good Stuff

- **Browser-based Bisq** — Access the full GUI from any modern browser
- **Auto-resize magic** — Window actually follows your browser size (took way too long to get this right)
- **Copy/paste via UI widget** — Click the tab thing on the left, use the clipboard box (browser security won't let us do it transparently)
- **Your data persists** — Wallet and settings survive container restarts
- **Easy updates** — One script, done
- **Actually secure** — Containers, resource limits, the works

### About That VPN Thing

Real talk: **in the Bisq context, VPN is NOT for privacy**. Tor already handles that perfectly fine.

The VPN option exists because some ISPs are jerks and block Tor connections. If your ISP does this annoying thing, route through a VPN first. Otherwise, skip it.

- **ISP blocks Tor?** → Use VPN bypass
- **ISP doesn't care?** → Direct connection (faster, simpler)

Your P2P trades still go through Tor either way. VPN just gets you to the internet when your ISP is being difficult.

## Quick Start (Actually Quick)

### Option 1: Super Quick Setup (30 seconds)

No git required - just grab the compose file and run:

```bash
# Download compose file directly
curl -o docker-compose.yml https://raw.githubusercontent.com/emsilva/bisq-vpn-docker/main/docker-compose.novpn.yml

# Start it up (uses pre-built image)
docker compose up -d
```

### Option 2: Full Setup (2 minutes)

```bash
git clone https://github.com/emsilva/bisq-vpn-docker.git
cd bisq-vpn-docker
cp .env.example .env
# Edit .env if you want custom settings
docker compose -f docker-compose.novpn.yml up -d
```

### Option 3: VPN Setup (ISP blocks Tor)

```bash
git clone https://github.com/emsilva/bisq-vpn-docker.git
cd bisq-vpn-docker
cp .env.example .env
vim .env  # Add your VPN settings
docker compose up -d
```

Then go to **http://localhost:6080** and use password `bisqvnc`.

Wait like 2 minutes for Bisq to actually start up (Java, am I right?).

## Prerequisites

You need Docker. If you don't have Docker, get Docker. Version 20.10+ works.

**⚡ Performance Note**: This setup now uses pre-built images from GitHub Container Registry. Setup time: **~30 seconds** vs **5+ minutes** for building locally.

Resource-wise:
- **4GB RAM minimum** (8GB if you don't hate yourself)
- **10GB disk space** (Bisq isn't tiny)
- **2+ CPU cores** (because waiting sucks)

For the VPN option, you also need a VPN that supports WireGuard. Most decent ones do.

## Detailed Setup

### Step 1: Get The Code

```bash
git clone https://github.com/emsilva/bisq-vpn-docker.git
cd bisq-vpn-docker
```

### Step 2: Configuration

```bash
cp .env.example .env
```

### Step 3A: Direct Connection (Recommended)

Most people should do this:

```bash
# Edit .env if you want (defaults are fine)
vim .env

# Start it up (now uses pre-built image - much faster!)
docker compose -f docker-compose.novpn.yml up -d
```

The important bits in `.env`:
```env
BISQ_VERSION=1.9.21          # Latest version
VNC_PASSWORD=bisqvnc         # Change if you care
TZ=America/Sao_Paulo         # Your timezone
PUID=1000                    # Your user ID
PGID=1000                    # Your group ID
```

### Step 3B: VPN Bypass (ISP Haters Only)

If your ISP blocks Tor like some kind of authoritarian regime:

```bash
mkdir -p volumes/gluetun/secrets
printf 'YOUR_WG_PRIVATE_KEY\n' > volumes/gluetun/secrets/wg_private_key
printf 'YOUR_WG_PRESHARED_KEY\n' > volumes/gluetun/secrets/wg_preshared_key  # leave empty if you don't use one
chmod 600 volumes/gluetun/secrets/wg_private_key volumes/gluetun/secrets/wg_preshared_key
vim .env  # fill in the non-secret bits below
```

Fill in the VPN section (keys stay in the files above):
```env
WIREGUARD_ADDRESSES=10.x.x.x/32
WIREGUARD_PUBLIC_KEY=server_public_key_here
WIREGUARD_ENDPOINT_IP=x.x.x.x  # IP address, not hostname
WIREGUARD_ENDPOINT_PORT=51820
```

Then:
```bash
docker compose up -d
```

### Step 4: Did It Work?

```bash
# Check if containers are alive
docker ps

# VPN people can test their IP
docker exec gluetun wget -qO- https://ipinfo.io/ip

# Watch Bisq wake up
docker logs bisq --tail 20
```

### Step 5: Use The Thing

Open **http://localhost:6080** and wait for Bisq to finish loading. It takes a minute because Java.

## What's In Here

```
bisq-vpn-docker/
├── docker-compose.yml          # VPN version
├── docker-compose.novpn.yml    # Normal version (use this one)
├── .env.example                # Configuration template
├── scripts/                    # Useful scripts
├── docker/bisq/                # Container build files
├── volumes/                    # Your important data lives here
└── security/                   # Security configs
```

**Critical**: `volumes/bisq-data/` contains your wallet. Back this up or cry later.

## Day-to-Day Operations

I made a script because typing Docker commands gets old:

```bash
# Start everything
./scripts/start-bisq-vpn.sh start

# Check if it's working
./scripts/start-bisq-vpn.sh status

# Read the logs
./scripts/start-bisq-vpn.sh logs

# Test VPN (if using)
./scripts/start-bisq-vpn.sh test

# Stop everything
./scripts/start-bisq-vpn.sh stop

# Pull latest pre-built image
docker compose pull

# Build from source (developers only)
./scripts/start-bisq-vpn.sh build
```

Or do it manually like a champion:

```bash
# Check VPN IP
docker exec gluetun wget -qO- https://ipinfo.io/ip

# Get a shell in the container
docker exec -it bisq bash

# Force window to fill screen
docker exec bisq bash -c 'DISPLAY=:1 wmctrl -r "Bisq" -b add,fullscreen'

# Watch resource usage
docker stats bisq
```

### Updating Bisq

```bash
./scripts/update-bisq.sh
```

This script checks for new versions, backs up your data, and rebuilds everything. Because automation is better than remembering.

## How This Actually Works

### Direct Connection Flow
```
Your Browser → noVNC → VNC → Desktop → Bisq → Internet
                                  ↓
                                Tor (for P2P)
```

### VPN Bypass Flow
```
Your Browser → noVNC → VNC → Desktop → Bisq → VPN → Internet
                                          ↓
                                        Tor (for P2P)
```

Either way, your actual trading goes through Tor. The VPN just helps you reach the internet when your ISP is being annoying.

## Configuration Reference

### Basic Settings (.env file)

| Setting | Default | What It Does |
|---------|---------|--------------|
| `BISQ_VERSION` | `1.9.21` | Which Bisq version to install |
| `VNC_PASSWORD` | `bisqvnc` | Password for the web interface |
| `TZ` | `America/Sao_Paulo` | Container timezone |
| `PUID` | `1000` | File ownership stuff |
| `PGID` | `1000` | More file ownership stuff |

### VPN Settings (Skip If Direct)

| Item | Required | Where/What |
|------|----------|------------|
| `volumes/gluetun/secrets/wg_private_key` | Yes | File content = your WireGuard private key (chmod 600) |
| `volumes/gluetun/secrets/wg_preshared_key` | Optional | File content = your preshared key (blank if none) |
| `WIREGUARD_ADDRESSES` | Yes | Your VPN IP (IPv4 only) |
| `WIREGUARD_PUBLIC_KEY` | Yes | Server's public key |
| `WIREGUARD_ENDPOINT_IP` | Yes | Server IP (must be IP, not domain) |
| `WIREGUARD_ENDPOINT_PORT` | Yes | Server port |

### Ports

| Port | What | Access |
|------|------|--------|
| `6080` | Web interface | http://localhost:6080 |
| `5901` | Direct VNC | VNC client to localhost:5901 |
| `8000` | Control server (internal only) | not published |
| `9999` | Health check (internal) | not published |

## Security Notes

### Data Safety
- **Back up `volumes/bisq-data/`** — Your wallet lives here
- Containers run as non-root
- Temporary filesystems for scratch space
- Resource limits prevent container abuse

### Network Security
- **Direct**: Standard Docker networking + Tor for P2P
- **VPN**: Everything routed through VPN + Tor for P2P
- Kill switch prevents IP leaks if VPN fails

## When Things Break

### VPN Won't Connect

```bash
# Check what's wrong
docker logs gluetun

# Test basic connectivity
docker exec gluetun ping -c 3 8.8.8.8
```

Common fixes:
- Make sure `WIREGUARD_ENDPOINT_IP` is an actual IP address
- Check if your VPN subscription is active
- Some VPN providers block Docker traffic (switch servers)

### Web Interface Dead

```bash
# Container status
docker ps

# Port conflicts
sudo netstat -tulpn | grep 6080

# noVNC logs
docker logs bisq | grep -i novnc
```

Usually just need to wait longer for startup, or something else grabbed port 6080.

### Window Size Issues

```bash
# Check resize monitor
docker exec bisq ps aux | grep monitor-resize

# Force fullscreen
docker exec bisq bash -c 'DISPLAY=:1 wmctrl -r "Bisq" -b add,fullscreen'
```

### Copy/Paste Issues

Real talk: Copy/paste isn't broken, it just doesn't work how you think it should. Browser security prevents transparent clipboard access, so here's how it actually works:

1. **Look for the control tab** — Small handle on the left edge of the screen
2. **Click it to open the panel** — Shows clipboard box and other controls
3. **To paste into Bisq**: Copy text normally, paste it into the noVNC clipboard box, it gets sent to Bisq
4. **To copy from Bisq**: Copy text in Bisq (Ctrl+C), it appears in the clipboard box, copy it from there

If the clipboard tools are actually broken:
```bash
# Check clipboard tools are running
docker exec bisq ps aux | grep -E "vncconfig|autocutsel"

# Restart them if needed
docker exec bisq bash -c 'DISPLAY=:1 vncconfig -nowin &'
docker exec bisq bash -c 'DISPLAY=:1 autocutsel -selection CLIPBOARD -fork'
```

### Performance Sucks

```bash
# Check resource usage
docker stats bisq

# See Java memory usage
docker exec bisq ps aux | grep java
```

Edit the compose file to give it more RAM if needed.

## Customization

### Custom Bisq Arguments

Edit `docker/bisq/config/start-bisq.sh`:
```bash
/opt/bisq/bin/Bisq \
  --baseCurrencyNetwork=BTC_MAINNET \
  --maxConnections=12 \
  --nodePort=9999
```

### More Resources

Edit your compose file:
```yaml
deploy:
  resources:
    limits:
      cpus: '6.0'
      memory: 8G
```

### Different VPN Providers

Edit `.env`:
```env
VPN_SERVICE_PROVIDER=mullvad  # or whatever
VPN_TYPE=wireguard
```

Check [Gluetun docs](https://github.com/qdm12/gluetun) for provider-specific settings.

## For Developers

### Building from Source

Want to modify the container or build locally? Create a `docker-compose.dev.yml`:

```yaml
services:
  bisq:
    build:
      context: docker/bisq
      dockerfile: Dockerfile
      args:
        - BISQ_VERSION=${BISQ_VERSION:-1.9.21}
    # ... rest of config same as docker-compose.novpn.yml
```

Then:
```bash
docker compose -f docker-compose.dev.yml up -d --build
```

### Testing Changes

```bash
# Test pre-built image
docker compose -f docker-compose.novpn.yml up -d

# Test local build
docker compose -f docker-compose.dev.yml up -d --build

# Test VPN setup
docker compose up -d
```

## Contributing

Found a bug? Have an idea? Cool.

1. Fork it
2. Make a branch
3. Fix/add stuff
4. Test with both pre-built and local builds
5. Open a PR

## License

MIT — Do whatever you want with this.

## Credits

- [Bisq](https://bisq.network/) — The actual Bitcoin exchange
- [Gluetun](https://github.com/qdm12/gluetun) — VPN container magic
- [TigerVNC](https://tigervnc.org/) — VNC server that doesn't suck
- [noVNC](https://novnc.com/) — Browser-based VNC client
- [LinuxServer.io](https://linuxserver.io) — Borrowed their s6-overlay approach, standardized base images, and `/config` volume patterns (because why reinvent working stuff?)

## Disclaimer

This works on my machine. It might work on yours. No guarantees about anything. Back up your wallet. Don't blame me if you lose money.

---

<p align="center">
<strong>Built by someone who got tired of installing the same app everywhere</strong><br>
<a href="https://github.com/emsilva/bisq-vpn-docker/issues">Report Issues</a> • 
<a href="https://github.com/emsilva/bisq-vpn-docker/discussions">Start Discussions</a> • 
<a href="https://bisq.wiki/">Bisq Docs</a>
</p>
