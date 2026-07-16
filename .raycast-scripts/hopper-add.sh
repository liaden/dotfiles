#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Hopper: Add Chore
# @raycast.mode compact
# @raycast.icon 🐇
# @raycast.packageName Shipping
# @raycast.argument1 { "type": "text", "placeholder": "one-line chore" }

export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
exec hopper add "$1"
