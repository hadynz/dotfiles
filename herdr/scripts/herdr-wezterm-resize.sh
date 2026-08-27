#!/usr/bin/env bash
# herdr-wezterm-resize.sh — Seamless resizing across nvim splits, herdr panes,
# and wezterm panes.
#
# Logic:
#   1. If the focused pane is running nvim → send the key so herdr-splits.nvim
#      handles nvim split resizing internally.
#   2. If a herdr neighbor exists in the direction → resize the herdr pane.
#   3. Otherwise (herdr edge) → no-op (wezterm handles its own resize).
#
# Usage (from herdr config.toml):
#   [[keys.command]]
#   key = "ctrl+left"
#   type = "shell"
#   command = "~/.config/herdr/scripts/herdr-wezterm-resize.sh left ctrl+left"

set -euo pipefail

direction="${1:?Usage: herdr-wezterm-resize.sh <left|right|up|down> <key>}"
key="${2:?Usage: herdr-wezterm-resize.sh <left|right|up|down> <key>}"

# Use herdr-provided env var for current pane, fall back to CLI
pane_id="${HERDR_ACTIVE_PANE_ID:-}"
if [ -z "$pane_id" ]; then
  pane_id=$(herdr pane current 2>/dev/null | jq -r '.result.pane.pane_id // empty') || true
fi

# Check if the foreground process is nvim/vim
fg_name=""
if [ -n "$pane_id" ]; then
  pane_json=$(herdr pane process-info --pane "$pane_id" 2>/dev/null) || true
  if [ -n "$pane_json" ]; then
    fg_name=$(echo "$pane_json" | jq -r '.result.process_info.foreground_processes[0].name // empty')
  fi
fi

if [[ "$fg_name" =~ ^n?vim$ ]]; then
  # Nvim is running — send the key so herdr-splits.nvim handles it
  herdr pane send-keys "$pane_id" "$key"
elif neighbor_json=$(herdr pane neighbor --direction "$direction" --pane "$pane_id" 2>/dev/null); then
  neighbor_pane_id=$(echo "$neighbor_json" | jq -r '.result.neighbor.pane_id // empty')
  if [ -n "$neighbor_pane_id" ] && [ "$neighbor_pane_id" != "$pane_id" ]; then
    # Real herdr neighbor — resize within herdr
    herdr pane resize --direction "$direction"
  fi
  # At herdr edge — no-op; wezterm handles its own resize
fi
