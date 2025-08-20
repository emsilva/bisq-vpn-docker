#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Monitor for desktop resolution changes and resize Bisq window accordingly
export DISPLAY=:1

# Get initial resolution
LAST_RES=$(xrandr | grep "^VNC-0" | grep -oP '\d+x\d+(?=\+)')
echo "Initial resolution: $LAST_RES"

# Function to maximize Bisq window - optimized for smooth resizing
maximize_bisq() {
    # Minimal delay for resolution change to settle
    sleep 0.2
    
    # Get current screen dimensions
    SCREEN_INFO=$(xrandr | grep "^VNC-0" | head -1)
    CURRENT_RES=$(echo "$SCREEN_INFO" | grep -oP '\d+x\d+(?=\+)')
    WIDTH=$(echo "$CURRENT_RES" | cut -d'x' -f1)
    HEIGHT=$(echo "$CURRENT_RES" | cut -d'x' -f2)
    
    echo "Screen dimensions: ${WIDTH}x${HEIGHT}"
    
    # Find Bisq window with optimized retry logic
    BISQ_WIN=""
    for attempt in {1..5}; do
        BISQ_WIN=$(wmctrl -l | grep -i "bisq" | head -1 | awk '{print $1}')
        if [ -n "$BISQ_WIN" ]; then
            echo "Found Bisq window: $BISQ_WIN"
            break
        fi
        if [ $attempt -eq 1 ]; then
            echo "Waiting for Bisq window..."
        fi
        sleep 1
    done
    
    if [ -n "$BISQ_WIN" ]; then
        # Try direct geometry setting first (faster than fullscreen toggle)
        wmctrl -i -r "$BISQ_WIN" -e 0,0,0,$WIDTH,$HEIGHT
        sleep 0.1
        
        # Fallback to fullscreen if geometry setting didn't work
        wmctrl -i -r "$BISQ_WIN" -b add,fullscreen
        
        echo "Resized Bisq window to ${WIDTH}x${HEIGHT}"
    else
        echo "Bisq window not found"
    fi
}

# Initial maximize - wait longer for Bisq to fully load
echo "Waiting for Bisq application to fully load..."
sleep 15
maximize_bisq

# Monitor for resolution changes with faster polling
echo "Monitoring for resolution changes..."
while true; do
    sleep 0.5  # Much faster polling for responsive resizing
    
    # Get current resolution
    CURRENT_RES=$(xrandr | grep "^VNC-0" | grep -oP '\d+x\d+(?=\+)')
    
    # Check if resolution changed
    if [ "$CURRENT_RES" != "$LAST_RES" ]; then
        echo "Resolution changed from $LAST_RES to $CURRENT_RES"
        LAST_RES="$CURRENT_RES"
        maximize_bisq
    fi
done