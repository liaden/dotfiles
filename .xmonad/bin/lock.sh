#!/usr/bin/env zsh
# Idle lock. bin/inhibit_{activate,deactivate} (mod+z / mod+shift+z) toggle this by
# pkill'ing xautolock and re-running this script, so xautolock stays the mechanism.
if ! command -v xautolock >/dev/null; then
    notify-send "Locker" "xautolock not installed - no idle lock active"
    exit 0
fi

# Lock at 5min idle; suspend 5min later if still idle. Never suspend as the locker
# itself - that reads as a hard freeze rather than a lock screen.
xautolock -time 5 -locker "xscreensaver-command -lock" \
          -notify 30 -notifier "notify-send 'Locker' 'Locking screen in 30 seconds'" \
          -killtime 5 -killer "systemctl suspend"
