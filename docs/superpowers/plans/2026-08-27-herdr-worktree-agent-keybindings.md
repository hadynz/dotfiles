# Herdr Worktree and Agent Keybindings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add native Herdr shortcuts for opening and removing worktrees and focusing agents 1–9, while disabling new-tab creation and indexed tab switching.

**Architecture:** Define the behavior through Herdr's native `[keys]` action settings in the existing configuration file. Keep all custom command bindings unchanged, validate through Herdr's configuration parser, and reload the running server so the new mappings take effect.

**Tech Stack:** TOML, Herdr 0.8.0 CLI

---

### Task 1: Configure and validate the native Herdr actions

**Files:**
- Modify: `herdr/config.toml:1`

- [ ] **Step 1: Confirm the current configuration is a valid baseline**

Run:

```bash
herdr config check
```

Expected output:

```text
config: ok
```

- [ ] **Step 2: Add the native key-action overrides**

Insert this table after `onboarding = false` and before `[ui.toast]` in `herdr/config.toml`:

```toml
[keys]
open_notification_target = ""
open_worktree = "prefix+o"
remove_worktree = "prefix+d"
new_tab = ""
switch_tab = ""
focus_agent = "prefix+1..9"
```

This explicitly frees `prefix+o` from its default notification action, assigns the worktree actions, moves `prefix+1..9` from tab switching to agent focusing, and disables new-tab creation.

- [ ] **Step 3: Validate the edited TOML and binding schema**

Run:

```bash
herdr config check
```

Expected output:

```text
config: ok
```

- [ ] **Step 4: Reload the running Herdr server**

Run:

```bash
herdr server reload-config
```

Expected: the command exits successfully without a configuration error.

- [ ] **Step 5: Revalidate after reload**

Run:

```bash
herdr config check
```

Expected output:

```text
config: ok
```

- [ ] **Step 6: Inspect the focused diff**

Run:

```bash
git diff --check -- herdr/config.toml
git diff -- herdr/config.toml
```

Expected: `git diff --check` prints nothing, and the diff contains only the new `[keys]` table. If the file is still untracked, use `git diff --no-index /dev/null herdr/config.toml` to inspect its complete contents and confirm the only intentional edit to the pre-existing file is the new table.

- [ ] **Step 7: Manually smoke-test non-destructive behavior**

In the running Herdr UI:

1. Press `prefix+o` and confirm the worktree picker opens; close it without removing anything.
2. Press `prefix+1` through the highest available agent number and confirm each shortcut focuses that agent.
3. Press `prefix+c` and confirm no new tab is created.
4. With multiple tabs present, press `prefix+1` and confirm it focuses an agent rather than switching tabs.
5. Press `prefix+d` only far enough to confirm Herdr presents its worktree-removal confirmation, then cancel it.

- [ ] **Step 8: Commit only the Herdr configuration**

```bash
git add herdr/config.toml
git diff --cached --check
git commit -m "feat: add Herdr worktree keybindings"
```

Expected: the commit contains `herdr/config.toml` and none of the user's unrelated working-tree changes.
