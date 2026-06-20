#!/usr/bin/env zsh
# xautolock -time 5 -locker "betterlockscreen -l" -notify 30 -nodtifier "notify-send 'Locker' 'Locking screen in 30 seconds'" -killtime 5 -killer "systemctl suspend"
xautolock -time 2 -locker "systemctl suspend"
