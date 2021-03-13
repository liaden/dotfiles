#!/usr/bin/env bash
while true
do
    feh --bg-fill "$(shuf -n 1 -e ~/Pictures/wallpapers/4k-portrait/*)" \
        --bg-fill "$(shuf -n 1 -e ~/Pictures/wallpapers/4k-landscape/*)"

    sleep 1200
done
