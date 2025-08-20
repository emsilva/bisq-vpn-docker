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
- **Copy/paste works** — Because basic functionality shouldn't be hard
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

### Option 1: Normal People Setup

```bash
git clone https://github.com/emsilva/bisq-vpn-docker.git
cd bisq-vpn-docker
cp .env.example .env
# Defaults are fine for most people
docker compose -f docker-compose.novpn.yml up -d
```

### Option 2: My ISP Is A Pain Setup

```bash
git clone https://github.com/emsilva/bisq-vpn-docker.git
cd bisq-vpn-docker
cp .env.example .env
# Edit .env with your VPN stuff
docker compose up -d
```

Then go to **http://localhost:6080** and use password `bisqvnc`.

Wait like 2 minutes for Bisq to actually start up (Java, am I right?).

## Prerequisites

You need Docker. If you don't have Docker, get Docker. Version 20.10+ works.

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
nano .env

# Start it up
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
nano .env
```

Fill in the VPN section:
```env
WIREGUARD_PRIVATE_KEY=your_private_key_here
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

# Rebuild when things break
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

| Setting | Required | What It Does |
|---------|----------|--------------|
| `WIREGUARD_PRIVATE_KEY` | Yes | Your WireGuard private key |
| `WIREGUARD_ADDRESSES` | Yes | Your VPN IP (IPv4 only) |
| `WIREGUARD_PUBLIC_KEY` | Yes | Server's public key |
| `WIREGUARD_ENDPOINT_IP` | Yes | Server IP (must be IP, not domain) |
| `WIREGUARD_ENDPOINT_PORT` | Yes | Server port |

### Ports

| Port | What | Access |
|------|------|--------|
| `6080` | Web interface | http://localhost:6080 |
| `5901` | Direct VNC | VNC client to localhost:5901 |
| `8000` | Health check | VPN setups only |

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

### Copy/Paste Broken

```bash
# Check clipboard tools
docker exec bisq ps aux | grep -E "vncconfig|autocutsel"

# Restart them
docker exec bisq bash -c 'DISPLAY=:1 vncconfig -nowin &'
docker exec bisq bash -c 'DISPLAY=:1 autocutsel -fork'
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

## Contributing

Found a bug? Have an idea? Cool.

1. Fork it
2. Make a branch
3. Fix/add stuff
4. Open a PR

### Testing

```bash
# Test both modes
docker compose -f docker-compose.novpn.yml up -d  # Direct
docker compose up -d                              # VPN
```

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