# Worktrunk smart local-worktree deletion

## Goal

Make `wt delete` a Fish-wrapper alias for native `wt remove`, and let both
`wt delete <target>` and `wt remove <target>` resolve a remembered substring of
an existing local worktree's branch name. Preserve native Worktrunk removal
safety and behavior whenever smart resolution does not produce exactly one
worktree.

## Scope

The wrapper will normalize the `delete` command name to `remove`. Smart matching
applies only when a remove invocation contains exactly one positional target.
Matching searches branch names checked out by local Git worktrees; it does not
search branches without worktrees or remote branches.

Existing native behavior remains unchanged for:

- `wt remove` or `wt delete` without a target, which removes the current
  worktree according to Worktrunk's rules.
- Invocations with multiple positional targets. The wrapper normalizes
  `delete` to `remove` but does not smart-match any target.
- Registered worktree paths, including detached worktree paths.
- Completion calls, repository-context options, discovery failures, and
  unsupported or unrecognized argument shapes.
- Worktrunk's confirmation, dirty-worktree checks, merged-branch checks,
  background removal, hooks, and force options.

## Command normalization

Normalize an initial `delete` command to `remove` before completion handling or
native dispatch. This gives `wt delete --help`, completion-mode invocations, and
ordinary calls the same native command surface as `wt remove` without defining
a second Fish function or a separate Worktrunk configuration alias.

All arguments following the command retain their order and spelling. Native
Worktrunk receives `remove` as the command name even when the user typed
`delete`.

## Remove argument classification

Use a small remove-specific argument parser to distinguish positional targets
from flags and flag values. It must handle options before or after the target,
including short-option clusters where Worktrunk permits them.

The parser has three relevant outcomes:

1. No positional target: pass through to native `remove`.
2. Exactly one positional target: the target is eligible for smart resolution.
3. More than one positional target: pass through to native `remove` without
   smart resolution.

Option values such as the values of `--format`, `--config`, and `--config-set`
must not be mistaken for removal targets. Repository-context forms using `-C`
bypass smart matching so discovery cannot accidentally inspect a different
repository from the one native Worktrunk will use. Boolean removal flags such
as `--force`, `-f`, `--force-delete`, `-D`, `--foreground`, `--reap`,
`--no-delete-branch`, and `--no-hooks` remain in place.

## Target resolution

Share the existing local-worktree resolver used by smart switch rather than
creating separate matching rules for removal. Treat the target as a literal,
case-insensitive string:

1. A single case-insensitive exact branch-name match takes precedence over
   containing names.
2. Otherwise, collect branch names containing the target case-insensitively.
3. One match replaces the positional target with its canonical branch name.
4. No match passes the original target through unchanged.
5. Multiple matches are sorted deterministically, printed to stderr, and cause
   status 1 without invoking native Worktrunk.

Before substring matching, detect registered local worktree paths and pass them
through unchanged. This preserves native branch-before-path resolution and
allows detached worktrees to be removed by path.

## Command flow

For a remove or delete invocation:

1. Normalize `delete` to `remove`.
2. Preserve the existing completion bypass and lazy native integration.
3. Classify the remove arguments.
4. If exactly one eligible target exists, discover local worktrees and resolve
   it with the shared matcher.
5. Replace only that positional argument when resolution is unique.
6. Invoke native Worktrunk with the normalized command and otherwise unchanged
   arguments.

Ambiguity is the only smart-resolution result that prevents native invocation.
This ensures an ambiguous request cannot partially remove a worktree.

## Error output

Ambiguity uses the same command-neutral message as smart switch:

```text
wt: '<target>' matches multiple local worktrees:
  <branch-one>
  <branch-two>
wt: retry with a more specific name
```

Canonical branch names are sorted so the output is deterministic. Native
Worktrunk remains responsible for all removal errors after successful or
pass-through resolution.

## Testing

Extend the existing Fish harness, which mocks native Worktrunk calls while
using real temporary Git worktrees. Add coverage for:

- `delete` normalizes to `remove`, including no-target and help-like calls.
- A unique partial target resolves for both `remove` and `delete`.
- Matching is case-insensitive and exact matches take precedence.
- Ambiguity returns nonzero, lists sorted candidates, and never invokes native
  Worktrunk.
- An unmatched target passes through unchanged.
- Options before and after the target remain in their original positions.
- Option values are not classified as targets.
- No-target and multiple-target calls retain native behavior.
- Registered and detached worktree paths remain native.
- `-C`, completion mode, discovery failure, and native status propagation are
  preserved.
- Existing smart-switch, Bitbucket URL, picker, lazy initialization, and source
  mode tests continue to pass.

The tests must never invoke real removal. All removal assertions stop at the
mocked native integration boundary.
