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
    sleep 0.5
    
    # Get current screen dimensions
    SCREEN_INFO=$(xrandr | grep "^VNC-0" | head -1)
    CURRENT_RES=$(echo "$SCREEN_INFO" | grep -oP '\d+x\d+(?=\+)')
    WIDTH=$(echo "$CURRENT_RES" | cut -d'x' -f1)
    HEIGHT=$(echo "$CURRENT_RES" | cut -d'x' -f2)
    
    echo "Screen changed to: ${WIDTH}x${HEIGHT}"
    
    # Find Bisq window
    BISQ_WIN=$(wmctrl -l | grep -i "bisq" | head -1 | awk '{print $1}')
    
    if [ -n "$BISQ_WIN" ]; then
        # Remove any existing window states first
        wmctrl -i -r "$BISQ_WIN" -b remove,fullscreen,maximized_vert,maximized_horz
        
        # Remove window decorations (title bar, borders)
        wmctrl -i -r "$BISQ_WIN" -b add,undecorated
        
        # Position window to fill entire screen without decorations
        wmctrl -i -r "$BISQ_WIN" -e 0,0,0,$WIDTH,$HEIGHT
        
        # Alternative: Try fullscreen mode if undecorated doesn't work
        wmctrl -i -r "$BISQ_WIN" -b add,fullscreen
        
        echo "Set Bisq window to fullscreen without decorations (${WIDTH}x${HEIGHT})"
    else
        echo "Bisq window not found"
    fi
}

# Initial maximize
sleep 5
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