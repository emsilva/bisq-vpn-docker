#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Monitor for desktop resolution changes and resize Bisq window accordingly
export DISPLAY=:1

# Get initial resolution
LAST_RES=$(xrandr | grep "^VNC-0" | grep -oP '\d+x\d+(?=\+)')
echo "Initial resolution: $LAST_RES"

# Function to maximize Bisq window
maximize_bisq() {
    # Wait a moment for the resolution change to settle
    sleep 1
    
    # Get current screen dimensions
    SCREEN_INFO=$(xrandr | grep "^VNC-0" | head -1)
    CURRENT_RES=$(echo "$SCREEN_INFO" | grep -oP '\d+x\d+(?=\+)')
    WIDTH=$(echo "$CURRENT_RES" | cut -d'x' -f1)
    HEIGHT=$(echo "$CURRENT_RES" | cut -d'x' -f2)
    
    echo "Screen dimensions: ${WIDTH}x${HEIGHT}"
    
    # Find Bisq window with retry logic
    BISQ_WIN=""
    for attempt in {1..10}; do
        BISQ_WIN=$(wmctrl -l | grep -i "bisq" | head -1 | awk '{print $1}')
        if [ -n "$BISQ_WIN" ]; then
            echo "Found Bisq window: $BISQ_WIN (attempt $attempt)"
            break
        fi
        echo "Waiting for Bisq window... (attempt $attempt/10)"
        sleep 2
    done
    
    if [ -n "$BISQ_WIN" ]; then
        # Remove any existing window states first
        wmctrl -i -r "$BISQ_WIN" -b remove,fullscreen,maximized_vert,maximized_horz
        sleep 0.2
        
        # Use fullscreen mode - most reliable approach
        wmctrl -i -r "$BISQ_WIN" -b add,fullscreen
        
        echo "Set Bisq window to fullscreen (${WIDTH}x${HEIGHT})"
        
        # Verify the change took effect
        sleep 0.5
        WINDOW_GEOM=$(wmctrl -l -G | grep "$BISQ_WIN")
        echo "Window geometry after resize: $WINDOW_GEOM"
    else
        echo "Bisq window not found after 10 attempts"
    fi
}

# Initial maximize - wait longer for Bisq to fully load
echo "Waiting for Bisq application to fully load..."
sleep 15
maximize_bisq

# Monitor for resolution changes
echo "Monitoring for resolution changes..."
while true; do
    sleep 2
    
    # Get current resolution
    CURRENT_RES=$(xrandr | grep "^VNC-0" | grep -oP '\d+x\d+(?=\+)')
    
    # Check if resolution changed
    if [ "$CURRENT_RES" != "$LAST_RES" ]; then
        echo "Resolution changed from $LAST_RES to $CURRENT_RES"
        LAST_RES="$CURRENT_RES"
        maximize_bisq
    fi
done