#!/usr/bin/env sh
# ~/.config/tmux/scripts/check-tpm.sh
# Print a warning to the client's tty (or stderr) if TPM is not installed,
# and also display a small sequence of status messages inside tmux.
#
# Intended path in repo: tmux/scripts/check-tpm.sh
# On the machine this should be copied to: ~/.config/tmux/scripts/check-tpm.sh
# Make executable: chmod +x ~/.config/tmux/scripts/check-tpm.sh

TPM_DIR="\$HOME/.tmux/plugins/tpm"

# Short messages to display inside tmux status/message area (they will show one-by-one)
STATUS_MESSAGES_POSIX='[tmux] TPM not found.
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
Then inside tmux press <Prefix>+I to install plugins.
'

# Full message to write to the client TTY (so it appears persistently in the shell)
MSG_FULL="$(
cat <<'EOF'

[tmux] TPM not found.

Install it with:

  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

Then inside tmux press <Prefix>+I to install plugins.

EOF
)"

# Only act if TPM is missing
if [ -d "\$TPM_DIR" ]; then
  exit 0
fi

# Try to write the full message to the current client's tty so the user sees it in their shell.
if command -v tmux >/dev/null 2>&1 && tmux display -p '#{client_tty}' >/dev/null 2>&1; then
  client_tty="\$(tmux display -p '#{client_tty}' 2>/dev/null)"
  if [ -n "\$client_tty" ] && [ -w "\$client_tty" ] 2>/dev/null; then
    printf "%s\n" "\$MSG_FULL" > "\$client_tty" || printf "%s\n" "\$MSG_FULL" >&2
  else
    # Fallback to stderr if tty is not writable
    printf "%s\n" "\$MSG_FULL" >&2
  fi
else
  # Not able to query client_tty; fallback to stderr
  printf "%s\n" "\$MSG_FULL" >&2
fi

# Display multiple short messages inside tmux (so they appear in the tmux message area).
if command -v tmux >/dev/null 2>&1; then
  # Iterate each non-empty line of STATUS_MESSAGES_POSIX and show it for a short period.
  printf "%s\n" "\$STATUS_MESSAGES_POSIX" | while IFS= read -r line; do
    [ -z "\$line" ] && continue
    tmux display-message "\$line" >/dev/null 2>&1 || true
    sleep 2
  done
fi

exit 0
