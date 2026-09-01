# Worktrunk Smart Delete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `wt delete` an alias for native `wt remove` and give both commands the existing smart local-worktree substring resolution when exactly one removal target is supplied.

**Architecture:** Normalize `delete` to `remove` at the wrapper boundary, classify remove arguments with a focused parser, and reuse a shared local-worktree target resolver for switch and removal. Preserve native Worktrunk behavior for no target, multiple targets, paths, repository-context options, discovery failures, and all actual removal safety checks.

**Tech Stack:** Fish 3.7 shell functions, Git worktree porcelain output, the existing Fish test harness, native Worktrunk shell integration.

---

## File map

- Modify `fish/custom-functions/wt.fish`: normalize the command alias, classify a single remove target, share local-worktree resolution, and rewrite only a uniquely matched target.
- Modify `fish/tests/wt_test.fish`: add parser, alias, smart-remove, ambiguity, option, path, completion, and native-pass-through coverage using the existing mock and temporary Git worktrees.
- Modify `README.md`: document `delete` as an alias and explain smart matching for both removal spellings.
- Reference `docs/superpowers/specs/2026-09-01-worktrunk-smart-delete-design.md`: approved behavior and safety contract.

### Task 1: Establish the baseline

**Files:**
- Verify: `fish/custom-functions/wt.fish`
- Verify: `fish/tests/wt_test.fish`

- [ ] **Step 1: Run the focused test suite before editing**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: `All wt Fish tests passed` and status 0.

- [ ] **Step 2: Run Fish syntax checks before editing**

Run:

```bash
fish -n fish/custom-functions/wt.fish
fish -n fish/tests/wt_test.fish
```

Expected: both commands exit 0 without output.

### Task 2: Normalize `delete` to native `remove`

**Files:**
- Modify: `fish/custom-functions/wt.fish:138-164`
- Test: `fish/tests/wt_test.fish`, immediately after sourcing `wt.fish`

- [ ] **Step 1: Add failing alias and completion tests**

Add this block after `source (status dirname)/../custom-functions/wt.fish`:

```fish
command rm -f "$WT_TEST_NATIVE_LOG"
wt delete
set -l call_status $status
_wt_test_assert_status 0 $call_status 'delete without a target should succeed'
_wt_test_assert_log 'remove' "$WT_TEST_NATIVE_LOG" 'delete should normalize to native remove'

command rm -f "$WT_TEST_BINARY_LOG" "$WT_TEST_NATIVE_LOG"
set -gx COMPLETE fish
wt delete --help
set call_status $status
set -e COMPLETE
_wt_test_assert_status 0 $call_status 'delete completion mode should succeed'
_wt_test_assert_log 'remove|--help' "$WT_TEST_BINARY_LOG" 'completion mode should normalize delete before calling the binary'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'delete completion mode should bypass the generated native function'
```

- [ ] **Step 2: Run the tests and verify the alias is red**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: failures show native Worktrunk received `delete` rather than `remove` in ordinary and completion-mode calls.

- [ ] **Step 3: Normalize arguments before completion dispatch**

In `wt`, create `native_args` immediately after setting `WORKTRUNK_BIN`, normalize the first argument, and make completion use the normalized arguments:

```fish
    set -l native_args $argv
    if test (count $native_args) -ge 1
        and test "$native_args[1]" = delete
        set native_args remove $native_args[2..-1]
    end

    # Let the binary emit completions directly and avoid recursing through the
    # wrapper when Worktrunk's completion script sets COMPLETE.
    if set -q COMPLETE
        command "$worktrunk_bin" $native_args
        return
    end
```

Remove the later duplicate `set -l native_args $argv`. Leave existing switch-specific `$argv` checks unchanged in this task.

- [ ] **Step 4: Run the focused suite**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: `All wt Fish tests passed`.

- [ ] **Step 5: Commit command normalization**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git diff --cached --check
git commit -m "feat: alias wt delete to remove"
```

### Task 3: Parse exactly one remove target

**Files:**
- Modify: `fish/custom-functions/wt.fish`, before `function wt`
- Test: `fish/tests/wt_test.fish`, after the pure matcher tests

- [ ] **Step 1: Add failing pure parser tests**

Add these assertions after the `__wt_match_local_worktree` unit cases:

```fish
set -l remove_target_index (__wt_single_remove_target_index cns-456 --force)
set -l parser_status $status
_wt_test_assert_status 0 $parser_status 'one remove target should be classified'
_wt_test_assert_equal '1' "$remove_target_index" 'the parser should return the target argument index'

set remove_target_index (__wt_single_remove_target_index --force cns-456 -D)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'flags around a remove target should be accepted'
_wt_test_assert_equal '2' "$remove_target_index" 'the parser should preserve a target after a flag'

set remove_target_index (__wt_single_remove_target_index --format json cns-456)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'option values should not count as targets'
_wt_test_assert_equal '3' "$remove_target_index" 'the parser should skip a separate format value'

set remove_target_index (__wt_single_remove_target_index cns-456 --format=json)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'attached option values should not count as targets'
_wt_test_assert_equal '1' "$remove_target_index" 'the parser should keep the positional target index'

set remove_target_index (__wt_single_remove_target_index -Dfv cns-456)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'boolean short-option clusters should be accepted'
_wt_test_assert_equal '2' "$remove_target_index" 'a short-option cluster should not count as a target'

set remove_target_index (__wt_single_remove_target_index -- -leading-target)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'the option delimiter should allow a leading-dash target'
_wt_test_assert_equal '2' "$remove_target_index" 'the parser should return the post-delimiter target index'

for parser_args in '' 'one two' '-C /tmp one' '-vC/tmp one' '--unknown one'
    set remove_target_index (__wt_single_remove_target_index (string split ' ' -- "$parser_args"))
    set parser_status $status
    _wt_test_assert_status 1 $parser_status "remove parser should preserve native handling for '$parser_args'"
    _wt_test_assert_equal '' "$remove_target_index" "remove parser should not select a target for '$parser_args'"
end
```

- [ ] **Step 2: Run the suite and verify the parser is undefined**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: failures include `Unknown command: __wt_single_remove_target_index`.

- [ ] **Step 3: Implement the remove argument classifier**

Add this helper before `function wt`:

```fish
# Print the one-based argument index when remove has exactly one eligible target.
# Return 1 for no target, multiple targets, repository context, or unknown syntax.
function __wt_single_remove_target_index
    set -l target_indexes
    set -l skip_next false
    set -l positional_only false
    set -l argument_index 0

    for arg in $argv
        set argument_index (math $argument_index + 1)

        if test "$skip_next" = true
            set skip_next false
            continue
        end

        if test "$positional_only" = true
            set -a target_indexes $argument_index
            continue
        end

        switch "$arg"
            case '--'
                set positional_only true
            case -C '-C*'
                return 1
            case --format --config --config-set
                set skip_next true
            case '--format=*' '--config=*' '--config-set=*'
                continue
            case --no-delete-branch --force-delete --foreground --reap --force --help --no-hooks --verbose --yes
                continue
            case '-*'
                if test "$arg" = '-'
                    return 1
                end

                for short_option in (string split '' -- (string sub --start 2 -- "$arg"))
                    switch "$short_option"
                        case C
                            return 1
                        case D f h v y
                            continue
                        case '*'
                            return 1
                    end
                end
            case '*'
                set -a target_indexes $argument_index
        end
    end

    if test "$skip_next" = true
        return 1
    end

    if test (count $target_indexes) -ne 1
        return 1
    end

    printf '%s\n' "$target_indexes[1]"
end
```

- [ ] **Step 4: Run parser and regression tests**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
fish -n fish/custom-functions/wt.fish fish/tests/wt_test.fish
```

Expected: all tests pass and both files parse successfully.

- [ ] **Step 5: Commit the parser**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git diff --cached --check
git commit -m "feat: classify Worktrunk remove targets"
```

### Task 4: Share local-worktree resolution

**Files:**
- Modify: `fish/custom-functions/wt.fish:6-94,208-225`
- Test: `fish/tests/wt_test.fish`

- [ ] **Step 1: Extract the discovery, path, and matching pipeline**

Add these helpers after `__wt_match_local_worktree`:

```fish
# Print one canonical branch for a unique match.
# Status 0: one match; 1: preserve native target; 2: ambiguous matches printed.
function __wt_resolve_local_worktree_target --argument-names target
    set -l worktree_branches (__wt_local_worktree_branches)
    set -l discovery_status $status
    test $discovery_status -eq 0; or return 1

    __wt_is_local_worktree_path "$target"; and return 1

    __wt_match_local_worktree "$target" $worktree_branches
end

function __wt_report_ambiguous_local_worktrees --argument-names target
    set -l matches $argv[2..-1]
    echo "wt: '$target' matches multiple local worktrees:" >&2
    printf '  %s\n' $matches >&2
    echo 'wt: retry with a more specific name' >&2
end
```

- [ ] **Step 2: Make smart switch call the shared resolver**

Replace the discovery/matcher portion of the smart-switch branch with:

```fish
        set -l worktree_matches (__wt_resolve_local_worktree_target "$argv[2]")
        set -l match_status $status
        if test $match_status -eq 0
            set native_args switch "$worktree_matches[1]" $argv[3..-1]
        else if test $match_status -eq 2
            __wt_report_ambiguous_local_worktrees "$argv[2]" $worktree_matches
            return 1
        end
```

- [ ] **Step 3: Run the full existing suite as a refactor gate**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
fish -n fish/custom-functions/wt.fish
```

Expected: `All wt Fish tests passed`; discovery failure, registered paths, exact matching, ambiguity, and option compatibility remain green.

- [ ] **Step 4: Commit the shared resolver refactor**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git diff --cached --check
git commit -m "refactor: share Worktrunk target resolution"
```

### Task 5: Smart-resolve one remove or delete target

**Files:**
- Modify: `fish/custom-functions/wt.fish`, in the wrapper dispatch chain
- Test: `fish/tests/wt_test.fish`, after the smart-switch integration cases

- [ ] **Step 1: Add failing unique-resolution tests for both spellings**

Add:

```fish
command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt remove cns-456 --force
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'smart remove should succeed'
_wt_test_assert_log 'remove|feature/CNS-456-smart-search|--force' "$WT_TEST_NATIVE_LOG" 'remove should use the canonical local-worktree branch'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt delete --no-hooks CNS-456
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'smart delete should succeed case-insensitively'
_wt_test_assert_log 'remove|--no-hooks|feature/CNS-456-smart-search' "$WT_TEST_NATIVE_LOG" 'delete should normalize and preserve option order around the resolved target'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt remove feature/CNS-123-smart-switch
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'exact smart remove should succeed'
_wt_test_assert_log 'remove|feature/CNS-123-smart-switch' "$WT_TEST_NATIVE_LOG" 'exact removal target should beat its containing followup branch'
```

- [ ] **Step 2: Run the tests and verify remove targets remain unresolved**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: failures show native Worktrunk received `cns-456` or `CNS-456` instead of `feature/CNS-456-smart-search`.

- [ ] **Step 3: Integrate single-target resolution into wrapper dispatch**

Add this final branch after smart-switch handling and before native integration initialization:

```fish
    else if test (count $native_args) -ge 1
        and test "$native_args[1]" = remove

        set -l remove_target_offset (__wt_single_remove_target_index $native_args[2..-1])
        set -l parser_status $status
        if test $parser_status -eq 0
            set -l remove_target_index (math $remove_target_offset + 1)
            set -l remove_target "$native_args[$remove_target_index]"
            set -l worktree_matches (__wt_resolve_local_worktree_target "$remove_target")
            set -l match_status $status
            if test $match_status -eq 0
                set native_args[$remove_target_index] "$worktree_matches[1]"
            else if test $match_status -eq 2
                __wt_report_ambiguous_local_worktrees "$remove_target" $worktree_matches
                return 1
            end
        end
    end
```

- [ ] **Step 4: Run the focused suite and verify unique resolution is green**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: `All wt Fish tests passed`.

- [ ] **Step 5: Add ambiguity and native-pass-through regressions**

Add:

```fish
command rm -f "$WT_TEST_NATIVE_LOG" "$WT_TEST_ERROR_LOG"
pushd "$smart_repo" >/dev/null
wt delete smart 2>"$WT_TEST_ERROR_LOG"
set call_status $status
popd >/dev/null
_wt_test_assert_status 1 $call_status 'ambiguous smart delete should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'ambiguous smart delete should not call Worktrunk'
_wt_test_assert_log "wt: 'smart' matches multiple local worktrees:|  feature/CNS-123-smart-switch|  feature/CNS-123-smart-switch-followup|  feature/CNS-456-smart-search|wt: retry with a more specific name" "$WT_TEST_ERROR_LOG" 'ambiguous smart delete should list sorted candidates and guidance'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt delete guaranteed-unmatched-target
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'unmatched smart delete should retain native behavior'
_wt_test_assert_log 'remove|guaranteed-unmatched-target' "$WT_TEST_NATIVE_LOG" 'unmatched delete should normalize but preserve its target'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt delete cns-456 smart
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'multiple delete targets should retain native behavior'
_wt_test_assert_log 'remove|cns-456|smart' "$WT_TEST_NATIVE_LOG" 'multiple targets should normalize without smart matching'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt delete "$detached_worktree"
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'detached worktree path deletion should remain native'
_wt_test_assert_log "remove|$detached_worktree" "$WT_TEST_NATIVE_LOG" 'registered paths should not be rewritten'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt delete cns-456 -C "$wt_test_tmp"
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'repository-context deletion should remain native'
_wt_test_assert_log "remove|cns-456|-C|$wt_test_tmp" "$WT_TEST_NATIVE_LOG" 'repository context should bypass smart discovery'

command rm -f "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_NATIVE_STATUS 29
pushd "$smart_repo" >/dev/null
wt delete guaranteed-unmatched-target
set call_status $status
popd >/dev/null
_wt_test_assert_status 29 $call_status 'native remove failure should pass through the delete alias'
_wt_test_assert_log 'remove|guaranteed-unmatched-target' "$WT_TEST_NATIVE_LOG" 'native failure should receive normalized remove arguments'
set -g WT_TEST_NATIVE_STATUS 0
```

- [ ] **Step 6: Run the complete Fish test suite**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
fish -n fish/custom-functions/wt.fish fish/tests/wt_test.fish
```

Expected: all tests pass and both Fish files parse successfully.

- [ ] **Step 7: Commit smart removal**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git diff --cached --check
git commit -m "feat: smart match Worktrunk removals"
```

### Task 6: Document and verify the completed behavior

**Files:**
- Modify: `README.md:58-65`
- Verify: `fish/custom-functions/wt.fish`
- Verify: `fish/tests/wt_test.fish`

- [ ] **Step 1: Document the alias and smart removal behavior**

Add these bullets under `### Worktrunk`:

```markdown
- `wt delete` is an alias for native `wt remove`.
- `wt remove <name>` and `wt delete <name>` resolve a unique, case-insensitive substring of one existing local worktree's branch name. Exact names take precedence; ambiguous names list their matches, while unmatched or multi-target calls retain native removal behavior.
```

- [ ] **Step 2: Run fresh completion verification**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
fish -n fish/custom-functions/wt.fish
fish -n fish/tests/wt_test.fish
git diff --check -- fish/custom-functions/wt.fish fish/tests/wt_test.fish README.md
```

Expected: the suite prints `All wt Fish tests passed`; both syntax checks and the diff check exit 0 without output.

- [ ] **Step 3: Inspect the scoped implementation diff**

Run:

```bash
git diff cf80757 -- fish/custom-functions/wt.fish fish/tests/wt_test.fish README.md
git status --short
```

Expected: the scoped diff contains only alias normalization, remove parsing/resolution, tests, and README documentation. Existing unrelated dirty dotfile changes remain unstaged.

- [ ] **Step 4: Commit README documentation**

```bash
git add README.md
git diff --cached --check
git commit -m "docs: explain smart Worktrunk deletion"
```

- [ ] **Step 5: Request an independent code review**

Use the `requesting-code-review` skill with:

```text
Description: Added wt delete as a native remove alias and smart single-target local-worktree matching for remove/delete.
Requirements: docs/superpowers/specs/2026-09-01-worktrunk-smart-delete-design.md
Base: cf80757
Head: current HEAD
Focus: Fish 3.7 compatibility, destructive-command safety, option parsing, target indexing, paths, ambiguity, native fallbacks, and regression coverage.
```

Expected: address every Critical or Important finding before completion.

- [ ] **Step 6: Run the final verification gate**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
fish -n fish/custom-functions/wt.fish
fish -n fish/tests/wt_test.fish
git diff --check cf80757..HEAD
git diff --cached --check
```

Expected: all tests pass, all syntax and diff checks exit 0, and no task files remain staged.
