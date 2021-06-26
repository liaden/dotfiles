#!/bin/sh
xrandr \
  --output DisplayPort-0 \
    --off \
  --output DisplayPort-1 \
    --mode 3840x2160 \
    --dpi 163 \
    --scale 1x1 \
    --pos 0x0 \
    --rotate left \
  --output DisplayPort-2 \
    --primary \
    --mode 3840x2160 \
    --dpi 163 \
    --scale 1x1 \
    --pos 2160x774 \
    --rotate normal \
  --output HDMI-A-0 \
    --off
