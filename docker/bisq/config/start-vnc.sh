#!/bin/bash

# Enable strict error handling  
set -euo pipefail

# Set proper environment
export DISPLAY=:1
export HOME=/home/bisq
export USER=bisq

DEFAULT_VNC_PASSWORD=${DEFAULT_VNC_PASSWORD:-bisqvnc}
EFFECTIVE_VNC_PASSWORD=${VNC_PASSWORD:-$DEFAULT_VNC_PASSWORD}
VNC_SENTINEL=/var/run/bisq/user-setup.done

echo "Waiting for user setup to finish..."
for i in {1..60}; do
    if [[ -f "$VNC_SENTINEL" ]]; then
        echo "User setup confirmed"
        break
    fi
    echo "Waiting for user setup... ($i/60)"
    sleep 1
done

if [[ ! -f "$VNC_SENTINEL" ]]; then
    echo "WARNING: User setup sentinel not found after 60 seconds, continuing anyway"
fi

TARGET_UID=$(getent passwd bisq | cut -d: -f3)
TARGET_GID=$(getent passwd bisq | cut -d: -f4)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

if [[ -n "$TARGET_UID" && "$CURRENT_UID" != "$TARGET_UID" ]] || [[ -n "$TARGET_GID" && "$CURRENT_GID" != "$TARGET_GID" ]]; then
    echo "Detected user remap (current ${CURRENT_UID}:${CURRENT_GID}, expected ${TARGET_UID:-?}:${TARGET_GID:-?}); restarting VNC launcher"
    exit 111
fi

echo "Starting VNC server..."

# Wait for VNC password file to exist (safety check)
echo "Checking for VNC password file..."
for i in {1..30}; do
    if [[ -f /home/bisq/.vnc/passwd ]]; then
        echo "VNC password file found"
        break
    fi
    echo "Waiting for VNC password file... ($i/30)"
    sleep 1
done

if [[ ! -f /home/bisq/.vnc/passwd ]]; then
    echo "ERROR: VNC password file not found after 30 seconds!"
    echo "Creating emergency password file..."
    printf '%s\n' "$EFFECTIVE_VNC_PASSWORD" | vncpasswd -f > /home/bisq/.vnc/passwd
    chmod 600 /home/bisq/.vnc/passwd
fi

# Clean up any existing locks
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null

# Start VNC server in background
/usr/bin/Xtigervnc :1 -geometry 1280x720 -depth 24 -localhost=0 -rfbport 5901 \
    -PasswordFile /home/bisq/.vnc/passwd -SecurityTypes VncAuth \
    -AcceptSetDesktopSize=on -desktop Bisq &

VNC_PID=$!

# Wait for VNC server to be ready
echo "Waiting for VNC server to start..."
for i in {1..30}; do
    if xset q &>/dev/null; then
        echo "VNC server is ready"
        break
    fi
    echo "Waiting for VNC server... ($i/30)"
    sleep 1
done

# Start desktop environment
echo "Starting desktop environment..."
bash /home/bisq/.vnc/xstartup &
DESKTOP_PID=$!

echo "VNC server and desktop started successfully"

# Keep script running and monitor both processes
while true; do
    if ! kill -0 $VNC_PID 2>/dev/null; then
        echo "VNC server died, exiting..."
        exit 1
    fi
    if ! kill -0 $DESKTOP_PID 2>/dev/null; then
        echo "Desktop session died, restarting..."
        bash /home/bisq/.vnc/xstartup &
        DESKTOP_PID=$!
    fi
    sleep 5
done
