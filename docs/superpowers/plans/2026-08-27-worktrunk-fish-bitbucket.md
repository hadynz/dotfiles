# Worktrunk Fish and Bitbucket Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dotfiles-managed Worktrunk configuration with `wt create <branch>` and make Fish resolve Bitbucket Cloud PR URLs passed to `wt switch` through `atlas prflow`.

**Architecture:** Keep Worktrunk's generated Fish shell integration behind a private `__worktrunk_native` function so it remains responsible for parent-shell directory changes. The public `wt` function intercepts only `wt switch <Bitbucket-PR-URL>`, resolves that URL to one source branch, and delegates all other arguments unchanged. A global Worktrunk alias handles fetch-before-create, while the existing installer owns the config-directory symlink.

**Tech Stack:** Fish shell, Worktrunk 0.74+, `atlas prflow`, TOML, Bash dotfiles installer

---

## File map

- Create `fish/tests/wt_test.fish`: isolated Fish assertions for Bitbucket dispatch and error paths.
- Create `fish/custom-functions/wt.fish`: lazy-load native Worktrunk integration privately and dispatch Bitbucket PR URLs.
- Create `worktrunk/config.toml`: personal Worktrunk aliases, beginning with `create`.
- Modify `setup.sh`: install/select/link/unlink the Worktrunk config directory through the existing component system.

### Task 1: Add the Fish Bitbucket dispatcher

**Files:**
- Create: `fish/tests/wt_test.fish`
- Create: `fish/custom-functions/wt.fish`

- [ ] **Step 1: Write the failing dispatcher tests**

Create `fish/tests/wt_test.fish`:

```fish
#!/usr/bin/env fish

set -g wt_test_failures 0
set -g wt_test_tmp (mktemp -d)
set -g wt_test_original_path $PATH
set -e WORKTRUNK_BIN

function _wt_test_cleanup --on-event fish_exit
    set -gx PATH $wt_test_original_path
    command rm -rf -- "$wt_test_tmp"
end

function _wt_test_fail --argument-names message
    echo "FAIL: $message" >&2
    set -g wt_test_failures (math $wt_test_failures + 1)
end

function _wt_test_assert_equal --argument-names expected actual message
    if test "$expected" != "$actual"
        _wt_test_fail "$message (expected '$expected', got '$actual')"
    end
end

function _wt_test_assert_status --argument-names expected actual message
    _wt_test_assert_equal "$expected" "$actual" "$message"
end

function _wt_test_logged_args --argument-names path
    if not test -s "$path"
        return
    end
    string join '|' (string split \n (string trim (string collect < "$path")))
end

set -gx WT_TEST_GENERATED_INTEGRATION "$wt_test_tmp/generated-wt.fish"
printf '%s\n' \
    'function wt' \
    '    printf "%s\n" $argv > "$WT_TEST_NATIVE_LOG"' \
    '    return $WT_TEST_NATIVE_STATUS' \
    'end' > "$WT_TEST_GENERATED_INTEGRATION"
printf '%s\n' \
    '#!/bin/sh' \
    'if [ "$1" = "config" ]; then' \
    '    /bin/cat "$WT_TEST_GENERATED_INTEGRATION"' \
    'fi' \
    'exit 0' > "$wt_test_tmp/wt"
chmod +x "$wt_test_tmp/wt"
set -gx PATH "$wt_test_tmp" $PATH

set -g WT_TEST_NATIVE_LOG "$wt_test_tmp/native.log"
set -g WT_TEST_ATLAS_LOG "$wt_test_tmp/atlas.log"
set -g WT_TEST_NATIVE_STATUS 0
set -g WT_TEST_ATLAS_STATUS 0
set -g WT_TEST_ATLAS_OUTPUT

function __worktrunk_native
    printf '%s\n' $argv > "$WT_TEST_NATIVE_LOG"
    return $WT_TEST_NATIVE_STATUS
end

function atlas
    printf '%s\n' $argv > "$WT_TEST_ATLAS_LOG"
    printf '%s\n' $WT_TEST_ATLAS_OUTPUT
    return $WT_TEST_ATLAS_STATUS
end

source (status dirname)/../custom-functions/wt.fish

set -l bitbucket_url 'https://bitbucket.org/atlassian/canvas/pull-requests/123'
set -g WT_TEST_ATLAS_OUTPUT 'feature/bitbucket-switch'
wt switch "$bitbucket_url" --no-hooks
set -l call_status $status
_wt_test_assert_status 0 $call_status 'Bitbucket switch should succeed'
_wt_test_assert_equal "prflow|branch|$bitbucket_url" (_wt_test_logged_args "$WT_TEST_ATLAS_LOG") 'Bitbucket URL should be passed to atlas prflow'
_wt_test_assert_equal 'switch|feature/bitbucket-switch|--no-hooks' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'resolved branch and trailing flags should reach Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
wt switch feature/local
set call_status $status
_wt_test_assert_status 0 $call_status 'ordinary branch switch should succeed'
_wt_test_assert_equal '' (_wt_test_logged_args "$WT_TEST_ATLAS_LOG") 'ordinary branch switch should not call atlas'
_wt_test_assert_equal 'switch|feature/local' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'ordinary branch switch should pass through unchanged'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -l github_url 'https://github.com/example/project/pull/456'
wt switch "$github_url"
set call_status $status
_wt_test_assert_status 0 $call_status 'GitHub URL switch should remain native'
_wt_test_assert_equal '' (_wt_test_logged_args "$WT_TEST_ATLAS_LOG") 'GitHub URL switch should not call atlas'
_wt_test_assert_equal "switch|$github_url" (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'GitHub URL switch should pass through unchanged'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
wt switch
set call_status $status
_wt_test_assert_status 0 $call_status 'picker invocation should succeed'
_wt_test_assert_equal '' (_wt_test_logged_args "$WT_TEST_ATLAS_LOG") 'picker invocation should not call atlas'
_wt_test_assert_equal 'switch' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'picker invocation should pass through unchanged'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_NATIVE_STATUS 23
wt list
set call_status $status
_wt_test_assert_status 23 $call_status 'native Worktrunk failure should pass through'
_wt_test_assert_equal 'list' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'non-switch commands should pass through unchanged'
set -g WT_TEST_NATIVE_STATUS 0

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_ATLAS_STATUS 42
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 42 $call_status 'atlas failure status should pass through'
_wt_test_assert_equal '' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'atlas failure should not call Worktrunk'
set -g WT_TEST_ATLAS_STATUS 0

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -e WT_TEST_ATLAS_OUTPUT
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 1 $call_status 'empty resolver output should fail'
_wt_test_assert_equal '' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'empty resolver output should not call Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_ATLAS_OUTPUT feature/one feature/two
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 1 $call_status 'multi-line resolver output should fail'
_wt_test_assert_equal '' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'multi-line resolver output should not call Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
functions --erase atlas
set -gx PATH "$wt_test_tmp"
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 127 $call_status 'missing atlas should fail with command-not-found status'
_wt_test_assert_equal '' (_wt_test_logged_args "$WT_TEST_NATIVE_LOG") 'missing atlas should not call Worktrunk'
set -gx PATH "$wt_test_tmp" $wt_test_original_path

if test $wt_test_failures -gt 0
    echo "$wt_test_failures test(s) failed" >&2
    exit 1
end

echo 'All wt Fish tests passed'
```

- [ ] **Step 2: Run the Fish tests to verify they fail**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: non-zero exit with at least the Bitbucket assertion failing because the existing wrapper forwards the URL directly to native Worktrunk and never calls `atlas prflow branch`.

- [ ] **Step 3: Replace the bootstrap stub with the dispatcher**

Create `fish/custom-functions/wt.fish` with:

```fish
# Worktrunk shell integration for Fish with Bitbucket Cloud PR URL support.
# Native shell integration is loaded as __worktrunk_native so this public
# function can resolve Bitbucket PRs before delegating to Worktrunk.

function wt
    set -l worktrunk_bin "$WORKTRUNK_BIN"
    if test -z "$worktrunk_bin"
        set worktrunk_bin (type -P wt 2>/dev/null)
    end

    if test -z "$worktrunk_bin"
        echo 'wt: command not found' >&2
        return 127
    end

    # The generated private function cannot see caller-local variables, so keep
    # the resolved binary in the global override shared with completions.
    set -g WORKTRUNK_BIN "$worktrunk_bin"

    # Let the binary emit completions directly and avoid recursing through the
    # wrapper when Worktrunk's completion script sets COMPLETE.
    if set -q COMPLETE
        command "$worktrunk_bin" $argv
        return
    end

    if not functions -q __worktrunk_native
        command "$worktrunk_bin" config shell init fish --cmd=__worktrunk_native | source
        set -l init_status $pipestatus[1]
        set -l source_status $pipestatus[2]
        test $init_status -eq 0; or return $init_status
        test $source_status -eq 0; or return $source_status
    end

    if test (count $argv) -ge 2
        and test "$argv[1]" = switch
        and string match --quiet --regex '^https?://bitbucket\.org/[^/]+/[^/]+/pull-requests/[0-9]+([/?#].*)?$' -- "$argv[2]"

        if not type -q atlas
            echo 'wt: atlas is required to resolve Bitbucket pull request URLs' >&2
            return 127
        end

        set -l branch_lines (atlas prflow branch "$argv[2]")
        set -l atlas_status $status
        if test $atlas_status -ne 0
            echo "wt: atlas prflow could not resolve $argv[2]" >&2
            return $atlas_status
        end

        set -l branches
        for line in $branch_lines
            set -l trimmed (string trim -- "$line")
            if test -n "$trimmed"
                set -a branches "$trimmed"
            end
        end

        if test (count $branches) -ne 1
            echo "wt: expected one branch from atlas prflow, got "(count $branches) >&2
            return 1
        end

        __worktrunk_native switch "$branches[1]" $argv[3..-1]
        return $status
    end

    __worktrunk_native $argv
end
```

- [ ] **Step 4: Validate Fish syntax**

Run:

```bash
fish -n fish/custom-functions/wt.fish fish/tests/wt_test.fish
```

Expected: exit 0 with no output.

- [ ] **Step 5: Run the dispatcher tests**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected:

```text
All wt Fish tests passed
```

- [ ] **Step 6: Verify real native bootstrap without changing worktrees**

Run:

```bash
fish --no-config -c 'source fish/custom-functions/wt.fish; wt --version'
```

Expected: exit 0 and output beginning with `wt v`.

- [ ] **Step 7: Commit the dispatcher**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git commit -m "feat: resolve Bitbucket PRs in wt switch"
```

### Task 2: Add the dotfiles-managed `wt create` alias

**Files:**
- Create: `worktrunk/config.toml`

- [ ] **Step 1: Verify the tracked config does not exist yet**

Run:

```bash
test ! -e worktrunk/config.toml
```

Expected: exit 0. If the file exists because work resumed after partial execution, inspect it against Step 2 instead of overwriting unrelated content.

- [ ] **Step 2: Create the Worktrunk user config**

Create `worktrunk/config.toml`:

```toml
[aliases]
create = "git fetch origin && wt switch --create {{ args }} --base origin/main"
```

The `&&` is required: a failed fetch must prevent creation from a stale `origin/main`.

- [ ] **Step 3: Validate and inspect the alias through Worktrunk**

Run:

```bash
wt --config "$PWD/worktrunk/config.toml" config alias show create
wt --config "$PWD/worktrunk/config.toml" config alias dry-run create -- sample-branch
```

Expected output includes both:

```text
git fetch origin && wt switch --create {{ args }} --base origin/main
git fetch origin && wt switch --create sample-branch --base origin/main
```

- [ ] **Step 4: Confirm a branch name is shell-escaped**

Run:

```bash
wt --config "$PWD/worktrunk/config.toml" config alias dry-run create -- 'sample branch'
```

Expected: exit 0 and rendered output quotes or escapes `sample branch` as one shell argument. This is a rendering check only; do not execute the alias with an invalid Git branch name.

- [ ] **Step 5: Commit the Worktrunk config**

```bash
git add worktrunk/config.toml
git commit -m "feat: add Worktrunk create alias"
```

### Task 3: Link Worktrunk through the dotfiles installer

**Files:**
- Modify: `setup.sh:27-43`
- Modify: `setup.sh` inside `unlink_all`

- [ ] **Step 1: Run the installer dry-run check before adding the component**

Run:

```bash
setup_test_home=$(mktemp -d)
HOME="$setup_test_home" ./setup.sh --all --dry-run | rg 'Processing: Worktrunk|Would link: worktrunk'
```

Expected: `rg` exits 1 because Worktrunk is not yet a selectable installer component.

- [ ] **Step 2: Add Worktrunk to the component list**

In `setup.sh`, add Worktrunk after Lazygit:

```bash
declare -a COMPONENTS=(
    "Fish Shell:fish:fish:fish:fish:0"
    "Neovim:neovim:MANUAL:nvim:nvim:0"
    "Tmux:tmux:tmux:tmux:tmux:0"
    "Lazygit:jesseduffield/lazygit/lazygit:lazygit:lazygit:lazygit:0"
    "Worktrunk:worktrunk:N/A:wt:worktrunk:0"
    "Starship:starship:MANUAL:starship:starship:0"
    "Wezterm:wezterm:MANUAL:wezterm:wezterm:1"
    "Herdr:herdr:N/A:herdr:herdr:0"
    "VSCode:visual-studio-code:MANUAL:code:vscode:1"
    "Cursor:cursor:N/A:cursor:vscode:1"
)
```

Preserve the existing Herdr entry and other uncommitted installer work. `N/A` intentionally makes Linux report that Worktrunk needs manual installation, while Homebrew installs the `worktrunk` formula on macOS.

- [ ] **Step 3: Include Worktrunk in unlink-all cleanup**

Change the package list inside `unlink_all` to:

```bash
local packages=("fish" "nvim" "tmux" "wezterm" "starship" "lazygit" "worktrunk")
```

This removes only the `~/.config/worktrunk` symlink during `--unstow`; Worktrunk's installed binary and any non-symlinked config are untouched.

- [ ] **Step 4: Re-run installer validation**

Run:

```bash
setup_test_home=$(mktemp -d)
HOME="$setup_test_home" ./setup.sh --all --dry-run | rg 'Processing: Worktrunk|Would link: worktrunk'
```

Expected: exit 0 with both lines present:

```text
Processing: Worktrunk
[DRY RUN] Would link: worktrunk → ~/.config/worktrunk
```

- [ ] **Step 5: Verify Bash syntax and the unlink registration**

Run:

```bash
bash -n setup.sh
rg -n 'local packages=.*"worktrunk"' setup.sh
```

Expected: both commands exit 0; the second prints the `unlink_all` package list.

- [ ] **Step 6: Commit only the Worktrunk installer hunks**

Because `setup.sh` already contains unrelated user changes, inspect and stage only the Worktrunk additions:

```bash
git diff -- setup.sh
git add -p setup.sh
git diff --cached -- setup.sh
git commit -m "feat: manage Worktrunk config in setup"
```

Expected staged diff: one Worktrunk component entry and `worktrunk` added to the unlink package list. Do not stage the existing Herdr or other unrelated hunks.

### Task 4: End-to-end non-destructive verification

**Files:**
- Verify: `fish/custom-functions/wt.fish`
- Verify: `fish/tests/wt_test.fish`
- Verify: `worktrunk/config.toml`
- Verify: `setup.sh`

- [ ] **Step 1: Run all syntax and unit checks**

Run:

```bash
fish -n fish/custom-functions/wt.fish fish/tests/wt_test.fish
fish --no-config fish/tests/wt_test.fish
bash -n setup.sh
git diff --check
```

Expected: every command exits 0; the Fish test prints `All wt Fish tests passed`; no whitespace errors are reported.

- [ ] **Step 2: Run Worktrunk config checks**

Run:

```bash
wt --config "$PWD/worktrunk/config.toml" config alias show create
wt --config "$PWD/worktrunk/config.toml" config alias dry-run create -- verification-branch
fish --no-config -c 'source fish/custom-functions/wt.fish; wt --version'
```

Expected: the alias is shown, the dry run renders `verification-branch` without executing it, and Worktrunk prints its version.

- [ ] **Step 3: Run the installer dry run in an isolated home**

Run:

```bash
setup_test_home=$(mktemp -d)
HOME="$setup_test_home" ./setup.sh --all --dry-run | rg 'Processing: Worktrunk|Would link: worktrunk'
```

Expected: both Worktrunk processing and link-preview lines are present. This command must not alter the real `~/.config/worktrunk`.

- [ ] **Step 4: Inspect final repository state**

Run:

```bash
git status --short
git log -4 --oneline
```

Expected: the three implementation commits are visible. Pre-existing unrelated modifications and untracked files may remain; no implementation files should be unexpectedly unstaged.

- [ ] **Step 5: Record the optional manual check**

After installation/linking is intentionally performed by the user, manually run this with a known same-repository Bitbucket Cloud PR:

```fish
read --prompt-str 'Bitbucket PR URL: ' bitbucket_pr_url
wt switch "$bitbucket_pr_url"
```

Expected: `atlas prflow` resolves the source branch, Worktrunk creates or selects its worktree, and Fish enters that directory. Do not automate this step because it creates local Git state and depends on a real authenticated PR.
