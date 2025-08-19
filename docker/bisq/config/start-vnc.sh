#!/bin/bash

# Set proper environment
export DISPLAY=:1
export HOME=/home/bisq
export USER=bisq

echo "Starting VNC server..."

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
/home/bisq/.vnc/xstartup &
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
        /home/bisq/.vnc/xstartup &
        DESKTOP_PID=$!
    fi
    sleep 5
done