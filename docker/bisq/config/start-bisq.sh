#!/bin/bash

# Enable strict error handling  
set -euo pipefail

echo "Waiting for desktop environment to start..."
sleep 20

# Set proper environment variables for Bisq user
export DISPLAY=:1
export HOME=/home/bisq
export USER=bisq
export XDG_CACHE_HOME=/home/bisq/.cache
export XDG_CONFIG_HOME=/home/bisq/.config
export XDG_DATA_HOME=/home/bisq/.local/share
export DCONF_USER_CONFIG_DIR=/home/bisq/.config/dconf

# Wait for X server to be ready
for i in {1..30}; do
    if xset q &>/dev/null; then
        echo "X server is ready"
        break
    fi
    echo "Waiting for X server... ($i/30)"
    sleep 1
done

echo "Starting Bisq in fullscreen..."
echo "Environment: HOME=$HOME USER=$USER XDG_CACHE_HOME=$XDG_CACHE_HOME"

# Ensure cache directories exist
mkdir -p /home/bisq/.cache/dconf /home/bisq/.config/dconf

# Start Bisq (window management handled by monitor-resize.sh)
/opt/bisq/bin/Bisq --baseCurrencyNetwork=BTC_MAINNET &
BISQ_PID=$!

echo "Bisq started with PID: $BISQ_PID"
echo "Window positioning will be handled by monitor-resize script"

# Keep script running so supervisor doesn't restart it
wait $BISQ_PID