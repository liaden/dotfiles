#!/bin/sh
# Monitor layout. Only touches connected outputs, since port names are not stable.

connected=$(xrandr -q | awk '/ connected/ {print $1}')
count=$(printf '%s\n' "$connected" | grep -c .)

[ "$count" -eq 0 ] && exit 0

if [ "$count" -eq 1 ]; then
    # Single display: landscape, preferred mode, no rotation.
    xrandr --output "$connected" --primary --auto --rotate normal --scale 1x1 --pos 0x0 --dpi 163

    # Make sure a stale layout hasn't left another output enabled.
    for out in $(xrandr -q | awk '/(dis)?connected/ {print $1}'); do
        [ "$out" = "$connected" ] || xrandr --output "$out" --off 2>/dev/null
    done
    exit 0
fi

main=$(~/.xmonad/bin/monitor-port main)
portrait=$(~/.xmonad/bin/monitor-port portrait | head -1)
if [ -n "$main" ] && [ -n "$portrait" ]; then
    xrandr \
      --output "$portrait" \
        --mode 3840x2160 \
        --dpi 163 \
        --scale 1x1 \
        --pos 0x0 \
        --rotate left \
      --output "$main" \
        --primary \
        --mode 3840x2160 \
        --dpi 163 \
        --scale 1x1 \
        --pos 2160x774 \
        --rotate normal
    exit 0
fi

# Two or more displays, but not the pair the layout was written for. Bring them
# up side by side rather than guessing at rotation.
set -- $connected
primary=$1
xrandr --output "$primary" --primary --auto --rotate normal --pos 0x0
shift
prev=$primary
for out in "$@"; do
    xrandr --output "$out" --auto --rotate normal --right-of "$prev" 2>/dev/null
    prev=$out
done
