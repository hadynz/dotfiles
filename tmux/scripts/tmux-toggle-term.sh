#!/bin/bash

# Script to toggle between floating terminal and normal terminal in tmux
# @see https://gist.github.com/pbnj/67c16c37918ba40bbb233b97f3e38456

set -uo pipefail

FLOAT_TERM="${1:-}"
LIST_PANES="$(tmux list-panes -F '#F' )"
PANE_ZOOMED="$(echo "${LIST_PANES}" | grep Z)"
PANE_COUNT="$(echo "${LIST_PANES}" | wc -l | bc)"

if [ -n "${FLOAT_TERM}" ]; then
  if [ "$(tmux display-message -p -F "#{session_name}")" = "popup" ]; then
    tmux detach-client
  else
    tmux popup -d '#{pane_current_path}' -xC -yC -w90% -h80% -E "tmux attach -t popup || tmux new -s popup"
  fi
else
  # Only one page (nvim) exists, create a new TMUX terminal in new split pane
  if [ "${PANE_COUNT}" = 1 ]; then
    tmux split-window -c "${PWD}"

  # Revert full screen
  elif [ -n "${PANE_ZOOMED}" ]; then
    tmux select-pane -t:.-

  # Full screen pane 0 (nvim)
  else
    tmux resize-pane -Z -t0
  fi
fi

