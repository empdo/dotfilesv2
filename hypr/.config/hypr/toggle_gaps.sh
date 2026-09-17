#!/bin/bash

# Where to store the toggle state
STATEFILE="$HOME/.cache/gaps_state"

# Default to "small" if file doesn’t exist
[ ! -f "$STATEFILE" ] && echo "small" > "$STATEFILE"

# Get currently focused workspace name
WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.name')

# Read saved state
state=$(cat "$STATEFILE")

if [ "$state" = "large" ]; then
    hyprctl keyword "workspace $WORKSPACE, gapsout:10, gapsin:5"
    echo "small" > "$STATEFILE"
else
    hyprctl keyword "workspace $WORKSPACE, gapsout:100, gapsin:5"
    echo "large" > "$STATEFILE"
fi
