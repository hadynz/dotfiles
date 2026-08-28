# Worktrunk Smart Local-Worktree Switching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve unique, case-insensitive substrings passed to `wt switch <target>` against existing local worktree branch names while preserving native Worktrunk behavior for exact, unmatched, and ineligible targets.

**Architecture:** Keep the public `wt` wrapper as the dispatcher. Add one pure branch-matching helper and one Git-porcelain discovery helper in `fish/custom-functions/wt.fish`; the wrapper invokes them only after Bitbucket URL handling and delegates the final canonical branch to the existing private Worktrunk integration. Extend the current Fish harness with pure resolver checks and integration tests backed by a temporary repository containing real local worktrees.

**Tech Stack:** Fish 3.7+, Git worktree porcelain output, Worktrunk shell integration, existing shell-based test harness

---

## File structure

- Modify `fish/custom-functions/wt.fish`: discover local worktree branches, perform literal case-insensitive resolution, and route `wt switch`.
- Modify `fish/tests/wt_test.fish`: test the pure matcher and wrapper behavior with temporary real Git worktrees.
- Modify `README.md`: document smart local-worktree switching and ambiguity behavior.

No new runtime dependency or source module is needed. The helpers stay beside the wrapper because they are private to that command and change with it.

### Task 1: Add the pure worktree-branch matcher

**Files:**
- Modify: `fish/tests/wt_test.fish:83-84`
- Modify: `fish/custom-functions/wt.fish:5`

- [ ] **Step 1: Write a failing unique-partial-match test**

Immediately after sourcing `wt.fish`, add:

```fish
set -l match_output (__wt_match_local_worktree smart feature/CNS-123-smart-switch feature/unrelated)
set -l match_status $status
_wt_test_assert_status 0 $match_status 'unique local-worktree substring should resolve'
_wt_test_assert_equal 'feature/CNS-123-smart-switch' "$match_output" 'unique substring should return the canonical branch'
```

- [ ] **Step 2: Run the test and verify the expected failure**

Run:

```bash
fish --no-config fish/tests/wt_test.fish
```

Expected: non-zero with Fish reporting that `__wt_match_local_worktree` is unknown and at least one new assertion failing. The existing Worktrunk assertions should remain unaffected.

- [ ] **Step 3: Implement the minimal matcher**

Add this before the public `wt` function:

```fish
# Print matching canonical branch names.
# Status 0: one match; 1: no match; 2: ambiguous.
function __wt_match_local_worktree --argument-names target
    set -l branches $argv[2..-1]
    set -l matches

    for branch in $branches
        if string match --quiet -- "*$target*" "$branch"
            set -a matches "$branch"
        end
    end

    if test (count $matches) -eq 1
        printf '%s\n' "$matches[1]"
        return 0
    end
    if test (count $matches) -eq 0
        return 1
    end

    printf '%s\n' $matches
    return 2
end
```

- [ ] **Step 4: Run the test and verify it passes**

Run `fish --no-config fish/tests/wt_test.fish`.

Expected: `All wt Fish tests passed` and exit 0.

- [ ] **Step 5: Commit the first resolver slice**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git commit -m "feat: match Worktrunk worktree names"
```

### Task 2: Harden matching semantics incrementally

**Files:**
- Modify: `fish/tests/wt_test.fish`
- Modify: `fish/custom-functions/wt.fish`

- [ ] **Step 1: Add a failing case-insensitive test**

Add after the unique-match assertion:

```fish
set match_output (__wt_match_local_worktree cns-123 feature/CNS-123-smart-switch feature/unrelated)
set match_status $status
_wt_test_assert_status 0 $match_status 'local-worktree matching should be case-insensitive'
_wt_test_assert_equal 'feature/CNS-123-smart-switch' "$match_output" 'case-insensitive matching should preserve canonical casing'
```

- [ ] **Step 2: Verify RED, then make substring matching case-insensitive**

Run `fish --no-config fish/tests/wt_test.fish` and expect the new case-insensitive assertion to fail.

Change the partial-match condition to:

```fish
if string match --ignore-case --quiet -- "*$target*" "$branch"
```

Run the test again and expect exit 0.

- [ ] **Step 3: Add a failing literal-metacharacter test**

```fish
set match_output (__wt_match_local_worktree 'a+b' feature/aaab feature/literal-a+b)
set match_status $status
_wt_test_assert_status 0 $match_status 'worktree target metacharacters should be literal'
_wt_test_assert_equal 'feature/literal-a+b' "$match_output" 'literal matching should not treat plus as a regex operator'

set match_output (__wt_match_local_worktree 'a*' feature/abcd feature/unrelated)
set match_status $status
_wt_test_assert_status 1 $match_status 'worktree target glob characters should be literal'
_wt_test_assert_equal '' "$match_output" 'literal glob characters should not create false matches'
```

- [ ] **Step 4: Verify RED, then replace glob matching with an escaped regex**

Run the Fish tests. Expected: the `a*` case resolves incorrectly because the current matcher treats `*` as a glob.

At the start of the matcher, create a safe literal pattern:

```fish
set -l target_pattern (string escape --style=regex -- "$target")
```

Replace the partial-match condition with:

```fish
if string match --ignore-case --quiet --regex -- "$target_pattern" "$branch"
```

Run the tests and expect exit 0.

- [ ] **Step 5: Add a failing exact-match-precedence test**

```fish
set match_output (__wt_match_local_worktree feature/foo feature/foo feature/foo-experiment)
set match_status $status
_wt_test_assert_status 0 $match_status 'an exact worktree name should beat partial matches'
_wt_test_assert_equal 'feature/foo' "$match_output" 'exact precedence should return only the exact branch'
```

- [ ] **Step 6: Verify RED, then add exact-match precedence**

Run the tests. Expected: status 2 because both candidates currently match as substrings.

Before collecting partial matches, add:

```fish
set -l target_lower (string lower -- "$target")
set -l exact_matches
for branch in $branches
    if test (string lower -- "$branch") = "$target_lower"
        set -a exact_matches "$branch"
    end
end

if test (count $exact_matches) -eq 1
    printf '%s\n' "$exact_matches[1]"
    return 0
end
if test (count $exact_matches) -gt 1
    printf '%s\n' (string sort --ignore-case -- $exact_matches)
    return 2
end
```

Run the tests and expect exit 0.

- [ ] **Step 7: Add and satisfy deterministic ambiguity tests**

Add:

```fish
set match_output (__wt_match_local_worktree FOO feature/Foo feature/foo)
set match_status $status
_wt_test_assert_status 2 $match_status 'multiple case-insensitive exact names should be ambiguous'
_wt_test_assert_equal (string join '|' (string sort --ignore-case -- feature/Foo feature/foo)) (string join '|' $match_output) 'ambiguous exact names should be sorted'

set match_output (__wt_match_local_worktree smart z-smart a-smart m-smart)
set match_status $status
_wt_test_assert_status 2 $match_status 'multiple partial worktree matches should be ambiguous'
_wt_test_assert_equal 'a-smart|m-smart|z-smart' (string join '|' $match_output) 'ambiguous partial names should be sorted'
```

Run the tests. Expected: the exact ambiguity assertion passes, while partial output ordering fails.

Before printing ambiguous partial matches, sort them:

```fish
set matches (string sort --ignore-case -- $matches)
```

Run the tests and expect exit 0.

- [ ] **Step 8: Commit hardened pure matching**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git commit -m "test: cover smart Worktrunk matching"
```

### Task 3: Discover branches from local Git worktrees

**Files:**
- Modify: `fish/tests/wt_test.fish`
- Modify: `fish/custom-functions/wt.fish`

- [ ] **Step 1: Create a real worktree fixture in the test harness**

After sourcing `wt.fish`, add:

```fish
set -l smart_repo "$wt_test_tmp/smart-switch-repo"
command git init --quiet --initial-branch=main "$smart_repo"
command git -C "$smart_repo" -c user.name=Test -c user.email=test@example.com commit --quiet --allow-empty -m initial

for branch in feature/CNS-123-smart-switch feature/CNS-456-smart-search feature/CNS-123-smart-switch-followup feature/literal-a+b
    command git -C "$smart_repo" branch "$branch"
    set -l worktree_name (string replace --all / - "$branch")
    command git -C "$smart_repo" worktree add --quiet "$wt_test_tmp/$worktree_name" "$branch"
end

command git -C "$smart_repo" branch feature/CNS-999-no-worktree
command git -C "$smart_repo" worktree add --quiet --detach "$wt_test_tmp/detached-worktree" HEAD
```

- [ ] **Step 2: Add a failing discovery test**

```fish
pushd "$smart_repo" >/dev/null
set -l discovered (__wt_local_worktree_branches)
set -l discovery_status $status
popd >/dev/null

_wt_test_assert_status 0 $discovery_status 'local worktree discovery should succeed inside a repository'
_wt_test_assert_equal 'feature/CNS-123-smart-switch|feature/CNS-123-smart-switch-followup|feature/CNS-456-smart-search|feature/literal-a+b|main' (string join '|' $discovered) 'discovery should return sorted checked-out branches only'
```

- [ ] **Step 3: Run the test and verify RED**

Run `fish --no-config fish/tests/wt_test.fish`.

Expected: non-zero because `__wt_local_worktree_branches` does not exist.

- [ ] **Step 4: Implement porcelain discovery**

Add before `__wt_match_local_worktree`:

```fish
# Print canonical branches checked out by local worktrees.
function __wt_local_worktree_branches
    set -l porcelain (command git worktree list --porcelain 2>/dev/null)
    set -l git_status $status
    test $git_status -eq 0; or return $git_status

    set -l branches
    for line in $porcelain
        if string match --quiet --regex '^branch refs/heads/' -- "$line"
            set -a branches (string replace 'branch refs/heads/' '' -- "$line")
        end
    end

    if test (count $branches) -gt 0
        printf '%s\n' $branches | string sort --unique
    end
end
```

- [ ] **Step 5: Run discovery and regression tests**

Run `fish --no-config fish/tests/wt_test.fish`.

Expected: all tests pass. The expected list excludes `feature/CNS-999-no-worktree` and the detached worktree.

- [ ] **Step 6: Commit local-worktree discovery**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git commit -m "feat: discover local Worktrunk worktrees"
```

### Task 4: Integrate smart resolution into `wt switch`

**Files:**
- Modify: `fish/tests/wt_test.fish`
- Modify: `fish/custom-functions/wt.fish:27-67`

- [ ] **Step 1: Add failing wrapper tests for unique resolution and argument forwarding**

After creating the worktree fixture, add:

```fish
command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch cns-456 --no-hooks
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'unique smart worktree switch should succeed'
_wt_test_assert_log 'switch|feature/CNS-456-smart-search|--no-hooks' "$WT_TEST_NATIVE_LOG" 'smart switch should pass the canonical branch and trailing arguments'
```

- [ ] **Step 2: Run the test and verify RED**

Run `fish --no-config fish/tests/wt_test.fish`.

Expected: the new log assertion fails because native Worktrunk receives `cns-456` unchanged.

- [ ] **Step 3: Wire successful and zero-match resolution into the wrapper**

Keep the contents of the existing Bitbucket block unchanged. Replace the `end`
that closes that condition with this mutually exclusive plain-target branch,
followed by the closing `end` shown below:

```fish
    else if test (count $argv) -ge 2
        and test "$argv[1]" = switch
        and test -n "$argv[2]"
        and not string match --quiet -- '-*' "$argv[2]"
        and not contains -- "$argv[2]" '@' '^'
        and not string match --ignore-case --quiet --regex '^https?://' -- "$argv[2]"

        set -l worktree_branches (__wt_local_worktree_branches)
        set -l discovery_status $status
        if test $discovery_status -eq 0
            set -l worktree_matches (__wt_match_local_worktree "$argv[2]" $worktree_branches)
            set -l match_status $status
            if test $match_status -eq 0
                set native_args switch "$worktree_matches[1]" $argv[3..-1]
            end
        end
    end
```

This deliberately leaves status 1 and discovery failure as native pass-through cases. Ambiguity is added in the next red/green step.

Run the tests and expect exit 0.

- [ ] **Step 4: Add failing exact-precedence and no-worktree pass-through tests**

```fish
command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch feature/CNS-123-smart-switch
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'exact worktree switch should succeed'
_wt_test_assert_log 'switch|feature/CNS-123-smart-switch' "$WT_TEST_NATIVE_LOG" 'exact branch should beat its containing followup branch'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch CNS-999
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'a branch without a worktree should use native pass-through'
_wt_test_assert_log 'switch|CNS-999' "$WT_TEST_NATIVE_LOG" 'branches without worktrees should not be smart-resolved'
```

Run the tests. Expected: both pass with the implementation from Step 3; retain them as integration coverage of the already test-driven helpers.

- [ ] **Step 5: Add a failing ambiguity behavior test**

At test setup, add:

```fish
set -g WT_TEST_ERROR_LOG "$wt_test_tmp/error.log"
```

Then add:

```fish
command rm -f "$WT_TEST_NATIVE_LOG" "$WT_TEST_ERROR_LOG"
pushd "$smart_repo" >/dev/null
wt switch smart 2>"$WT_TEST_ERROR_LOG"
set call_status $status
popd >/dev/null
_wt_test_assert_status 1 $call_status 'ambiguous smart switch should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'ambiguous smart switch should not call Worktrunk'
_wt_test_assert_log "wt: 'smart' matches multiple local worktrees:|  feature/CNS-123-smart-switch|  feature/CNS-123-smart-switch-followup|  feature/CNS-456-smart-search|wt: retry with a more specific name" "$WT_TEST_ERROR_LOG" 'ambiguous smart switch should list sorted candidates and guidance'
```

- [ ] **Step 6: Run the test and verify RED**

Run `fish --no-config fish/tests/wt_test.fish`.

Expected: Worktrunk is invoked with `smart`, so the status, native log, and error output assertions fail.

- [ ] **Step 7: Handle ambiguity without invoking Worktrunk**

Extend the matcher status handling added in Step 3:

```fish
            if test $match_status -eq 0
                set native_args switch "$worktree_matches[1]" $argv[3..-1]
            else if test $match_status -eq 2
                echo "wt: '$argv[2]' matches multiple local worktrees:" >&2
                printf '  %s\n' $worktree_matches >&2
                echo 'wt: retry with a more specific name' >&2
                return 1
            end
```

Run the tests and expect exit 0.

- [ ] **Step 8: Add discovery-failure and ineligible-target regression tests**

Use a directory outside a Git repository to prove discovery failure remains native:

```fish
command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$wt_test_tmp" >/dev/null
wt switch unknown-target
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'discovery failure should preserve native behavior'
_wt_test_assert_log 'switch|unknown-target' "$WT_TEST_NATIVE_LOG" 'discovery failure should pass the original target through'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch --create feature/new
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'option-like switch forms should remain native'
_wt_test_assert_log 'switch|--create|feature/new' "$WT_TEST_NATIVE_LOG" 'option-like targets should bypass smart resolution'
```

Run `fish --no-config fish/tests/wt_test.fish` and expect all tests to pass. Existing GitHub URL, Bitbucket URL, picker, lazy initialization, and status propagation assertions must also remain green.

- [ ] **Step 9: Commit wrapper integration**

```bash
git add fish/custom-functions/wt.fish fish/tests/wt_test.fish
git commit -m "feat: smart switch local Worktrunk worktrees"
```

### Task 5: Document and verify the completed behavior

**Files:**
- Modify: `README.md:56-63`
- Verify: `fish/custom-functions/wt.fish`
- Verify: `fish/tests/wt_test.fish`

- [ ] **Step 1: Update the Worktrunk usage documentation**

Add these bullets after the existing Bitbucket URL bullet:

```markdown
- `wt switch <name>` resolves a unique, case-insensitive substring of an existing local worktree's branch name.
- Exact worktree branch names take precedence. Ambiguous substrings list their matches and ask for a more specific name; unmatched targets retain native Worktrunk behavior.
```

- [ ] **Step 2: Run the full focused verification**

```bash
fish --no-config fish/tests/wt_test.fish
fish -n fish/custom-functions/wt.fish
fish -n fish/tests/wt_test.fish
git diff --check -- fish/custom-functions/wt.fish fish/tests/wt_test.fish README.md
```

Expected: Fish prints `All wt Fish tests passed`; both syntax checks and the scoped diff check exit 0.

- [ ] **Step 3: Inspect the final scoped diff**

```bash
git diff b2b7639 -- fish/custom-functions/wt.fish fish/tests/wt_test.fish README.md
git status --short
```

Expected: only smart-switch changes appear in the scoped diff. Pre-existing unrelated working-tree changes remain present and unstaged.

- [ ] **Step 4: Commit documentation**

```bash
git add README.md
git commit -m "docs: explain smart Worktrunk switching"
```
