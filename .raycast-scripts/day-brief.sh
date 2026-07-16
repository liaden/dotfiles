#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Day Brief
# @raycast.mode fullOutput
# @raycast.icon ☀️
# @raycast.packageName Shipping

# Raycast runs scripts with a bare environment (no login shell), so PATH
# must cover homebrew (gh, jq, claude) and ~/bin explicitly.
export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
exec day-brief
