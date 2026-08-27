# Herdr worktree and agent keybindings

## Goal

Make worktree management and direct agent selection convenient while removing tab shortcuts that are not part of the user's normal workflow.

## Configuration design

Add an explicit `[keys]` table before the existing `[[keys.command]]` entries in `herdr/config.toml`:

```toml
[keys]
open_notification_target = ""
open_worktree = "prefix+o"
remove_worktree = "prefix+d"

new_tab = ""
switch_tab = ""
focus_agent = "prefix+1..9"
```

The resulting behavior is:

- `prefix+o` opens the worktree picker. The existing notification-target action is explicitly unbound so the key is not ambiguous.
- `prefix+d` opens Herdr's worktree-removal confirmation flow.
- `prefix+1` through `prefix+9` focus the corresponding agent.
- The new-tab action and indexed tab-switching shortcuts are disabled.
- Other tab actions and all existing custom commands, navigation bindings, resize bindings, and plugin bindings remain unchanged.

Native Herdr key settings are preferred over custom shell commands because they preserve Herdr's built-in UI and confirmation behavior.

## Validation

Run `herdr config check` after editing the file, then reload the running server with `herdr server reload-config`. Re-run `herdr config check` after reload. Do not invoke worktree removal as part of automated validation.

Manual confirmation consists of opening the worktree picker with `prefix+o` and selecting a non-destructive target, then checking `prefix+1..9` against available agent rows. Confirm that `prefix+c` and `prefix+1..9` no longer create or select tabs.
