#!/usr/bin/env bash
# herdr-wezterm-nav.sh — Drop-in replacement for herdr-splits' nav action
# that adds wezterm pane escape at herdr edges.
#
# This is a fork of herdr-splits/scripts/herdr-nav.sh with one change:
# when nav_at_edge=stop and we're at an edge, instead of doing nothing
# we call `wezterm cli activate-pane-direction` to escape to wezterm.
#
# Usage: herdr-wezterm-nav.sh <left|down|up|right>

set -euo pipefail

dir="${1:?usage: herdr-wezterm-nav.sh <left|down|up|right>}"
herdr="${HERDR_BIN_PATH:-herdr}"

case "$dir" in
  left)  key="ctrl+h"; config_key="nav_key_left"; opp="right"; wez_dir="Left" ;;
  down)  key="ctrl+j"; config_key="nav_key_down"; opp="up"; wez_dir="Down" ;;
  up)    key="ctrl+k"; config_key="nav_key_up"; opp="down"; wez_dir="Up" ;;
  right) key="ctrl+l"; config_key="nav_key_right"; opp="left"; wez_dir="Right" ;;
  *) echo "herdr-wezterm-nav.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

# Resolve config from the shared herdr-splits config file.
unzoom=1
nav_at_edge=stop
config_path="${HERDR_SPLITS_CONFIG:-${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/config/herdr-splits}/herdr-splits.conf}"
if [ -r "$config_path" ]; then
  configured_key=$(sed -n -E "s/^[[:space:]]*${config_key}[[:space:]]*=[[:space:]]*([^[:space:]#]+).*$/\\1/p" "$config_path" | tail -n 1)
  if [ -n "$configured_key" ]; then
    key="$configured_key"
  fi
  if grep -Eq '^[[:space:]]*unzoom_on_nav[[:space:]]*=[[:space:]]*false' "$config_path"; then
    unzoom=0
  fi
  if grep -Eq '^[[:space:]]*nav_at_edge[[:space:]]*=[[:space:]]*wrap' "$config_path"; then
    nav_at_edge=wrap
  fi
fi

# Get focused pane ID.
pane_id=$("$herdr" pane current --current 2>/dev/null | grep -o '"pane_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)

# Check if focused pane is running vim/nvim.
is_vim=0
if [ -n "$pane_id" ] && pane_info=$("$herdr" pane process-info --current 2>/dev/null); then
  if echo "$pane_info" | grep -qiE '"name"[[:space:]]*:[[:space:]]*"(g?(view|l?n?vim?x?)(diff)?)"' 2>/dev/null; then
    is_vim=1
  fi
fi

# Vim pane: forward the chord; the Neovim plugin handles splits + edge escape.
if [ "$is_vim" -eq 1 ]; then
  exec "$herdr" pane send-keys "$pane_id" "$key"
fi

# --- Non-vim Herdr pane ---

edges_out=$("$herdr" pane edges --current 2>/dev/null || true)

edges_trusted=1
if printf '%s' "$edges_out" | grep -q '"zoomed"[[:space:]]*:[[:space:]]*true'; then
  if [ "$unzoom" -eq 1 ]; then
    "$herdr" pane zoom --off --current 2>/dev/null || true
    edges_out=$("$herdr" pane edges --current 2>/dev/null || true)
  else
    edges_trusted=0
  fi
fi

if [ "$edges_trusted" -eq 1 ] && printf '%s' "$edges_out" | grep -q "\"$dir\"[[:space:]]*:[[:space:]]*true"; then
  if [ "$nav_at_edge" = stop ]; then
    # ── THIS IS THE KEY CHANGE ──
    # At herdr edge with stop: escape to wezterm parent pane
    exec wezterm cli activate-pane-direction "$wez_dir"
  fi
  exec "$herdr" pane focus --direction "$opp" --current
else
  exec "$herdr" pane focus --direction "$dir" --current
fi
