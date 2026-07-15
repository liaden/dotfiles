#!/usr/bin/env bash
# Claude Code statusLine command
# Mirrors the Powerlevel10k rainbow prompt style:
#   left:  dir  git-branch+status
#   right: model  context%

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# --- directory (basename only, like p10k \W) ---
dir=$(basename "$cwd")

# --- git branch + dirty marker ---
git_info=""
if git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_dirty=""
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    git_dirty=" *"
  fi
  git_info="$git_branch$git_dirty"
fi

# --- turn timer (state maintained by ~/bin/claude-session-hook) ---
# working: elapsed on the current turn; idle: when the last turn finished.
# stopped_at only moves on the Stop hook, i.e. a fully finished response.
turn_info=""
state="$HOME/.local/state/claude-sessions/$session_id.json"
if [ -n "$session_id" ] && [ -f "$state" ]; then
  now=$(date +%s)
  fmt_dur() {
    if   [ "$1" -ge 3600 ]; then printf '%dh%02dm' "$(($1 / 3600))" "$(($1 % 3600 / 60))"
    elif [ "$1" -ge 60 ];   then printf '%dm%02ds' "$(($1 / 60))" "$(($1 % 60))"
    else                         printf '%ds' "$1"
    fi
  }
  fmt_clock() { date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M; }
  status=$(jq -r '.status // empty' "$state")
  prompt_at=$(jq -r '.prompt_at // 0' "$state")
  stopped_at=$(jq -r '.stopped_at // 0' "$state")
  case "$status" in
    working) [ "$prompt_at" -gt 0 ]  && turn_info="✳ $(fmt_dur $((now - prompt_at)))" ;;
    waiting) [ "$prompt_at" -gt 0 ]  && turn_info="⏸ needs you $(fmt_dur $((now - prompt_at)))" ;;
    idle)    [ "$stopped_at" -gt 0 ] && turn_info="✓ $(fmt_clock "$stopped_at") +$(fmt_dur $((now - stopped_at)))" ;;
  esac
fi

# --- context bar ---
ctx_info=""
if [ -n "$used_pct" ]; then
  printf -v used_int "%.0f" "$used_pct"
  ctx_info="${used_int}% ctx"
fi

# --- assemble with ANSI colors (dimmed-friendly) ---
# p10k rainbow uses bold blue for dir, bold cyan for git, bold green for model
reset='\033[0m'
blue='\033[34m'
cyan='\033[36m'
green='\033[32m'
yellow='\033[33m'
magenta='\033[35m'

parts=()

# directory segment
[ -n "$dir" ] && parts+=("$(printf "${blue}%s${reset}" "$dir")")

# git segment
[ -n "$git_info" ] && parts+=("$(printf "${cyan}%s${reset}" "$git_info")")

# turn timer segment
[ -n "$turn_info" ] && parts+=("$(printf "${magenta}%s${reset}" "$turn_info")")

# model segment
[ -n "$model" ] && parts+=("$(printf "${green}%s${reset}" "$model")")

# context segment
[ -n "$ctx_info" ] && parts+=("$(printf "${yellow}%s${reset}" "$ctx_info")")

# join with separator
output=""
for part in "${parts[@]}"; do
  if [ -z "$output" ]; then
    output="$part"
  else
    output="$output  $part"
  fi
done

printf "%b\n" "$output"
