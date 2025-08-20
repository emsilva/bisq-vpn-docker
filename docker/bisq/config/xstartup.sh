#!/bin/bash

# Enable strict error handling  
set -euo pipefail

export DISPLAY=:1
export HOME=/home/bisq
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

echo "Starting XFCE desktop..."
startxfce4 &
SESSION_PID=$!

# Wait for X server and desktop to be ready
for i in {1..30}; do
    if xset q &>/dev/null; then
        echo "X server is ready"
        break
    fi
    echo "Waiting for X server... ($i/30)"
    sleep 1
done

sleep 3

# Enable clipboard support
echo "Starting clipboard tools..."
vncconfig -nowin &
autocutsel -selection CLIPBOARD -fork
autocutsel -selection PRIMARY -fork

# Clean up desktop environment for better fullscreen experience
echo "Cleaning up desktop environment..."
(sleep 3 && xfce4-panel -q 2>/dev/null && echo "Panel killed") &
(sleep 3 && killall xfce4-screensaver 2>/dev/null && echo "Screensaver killed") &

# Disable screen blanking
(sleep 3 && xset s off && xset s noblank && xset -dpms && echo "Screen blanking disabled") &

# Ensure desktop is ready before Bisq starts
sleep 2

# Keep script running to maintain desktop session
echo "Desktop environment started"
wait $SESSION_PID