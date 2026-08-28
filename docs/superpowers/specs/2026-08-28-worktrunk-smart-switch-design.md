# Worktrunk smart local-worktree switching

## Goal

Make `wt switch <target>` convenient when the user remembers only part of an
existing local worktree's branch name. Preserve native Worktrunk behavior when
the wrapper cannot resolve exactly one local worktree.

## Scope

The Fish `wt` wrapper will extend only the common `wt switch <target>` form.
Matching applies to branch names checked out by local Git worktrees. It does not
search other local branches, remote branches, worktree paths, or detached
worktrees.

Existing behavior remains unchanged for:

- `wt switch` without a target, including the native picker.
- Bitbucket Cloud pull-request URLs resolved through `atlas prflow`.
- Option-like targets, Worktrunk shortcuts, completion calls, and commands other
  than `switch`.
- Arguments following the switch target.

## Worktree discovery

Use `git worktree list --porcelain` as the machine-readable source. Parse only
`branch refs/heads/<name>` records, strip the `refs/heads/` prefix, and
deduplicate branch names. Records without a branch line are detached worktrees
and are ignored. If discovery fails, preserve native behavior by passing the
original command through unchanged.

This keeps discovery local and dependency-free. In particular, do not use
`git branch`, because branches without worktrees are outside scope, and do not
use `wt list --format=json`, because that would add JSON schema handling or a
`jq` dependency to the wrapper.

## Resolution rules

Treat `<target>` as a literal, case-insensitive string:

1. If exactly one branch name equals `<target>` case-insensitively, use that
   exact match. Exact-match precedence applies even when other branch names
   contain the same text. Multiple case-insensitive exact matches are
   ambiguous.
2. Otherwise, collect branch names that contain `<target>`
   case-insensitively.
3. If exactly one branch matches, replace the target with its canonical branch
   name and invoke native Worktrunk.
4. If no branch matches, pass the original target to native Worktrunk unchanged.
5. If multiple branches match, sort their canonical names case-insensitively,
   print them, ask the user to retry with a more specific target, return status
   1, and do not invoke native Worktrunk.

Matching must escape regex or glob metacharacters in user input so characters
such as `.`, `*`, `[`, and `?` remain literal.

## Command flow

The wrapper will retain its existing binary discovery, completion bypass, and
lazy loading of `__worktrunk_native`.

For `wt switch <target> [args...]`, resolution order is:

1. Resolve a supported Bitbucket pull-request URL as today.
2. For an eligible plain target, attempt smart local-worktree resolution.
3. Invoke `__worktrunk_native switch <resolved-or-original-target> [args...]`.

Ambiguity is the only smart-resolution result that prevents native invocation.
Failures from native Worktrunk continue to pass through unchanged.

## Error output

An ambiguous target should produce a concise message on stderr in this shape:

```text
wt: '<target>' matches multiple local worktrees:
  <branch-one>
  <branch-two>
wt: retry with a more specific name
```

The output should use canonical branch names and be deterministic so it remains
readable and testable.

## Testing

Extend the existing Fish test harness using temporary Git repositories and real
`git worktree` metadata. Add coverage for:

- A unique partial match resolves to its canonical branch name.
- Matching is case-insensitive.
- An exact match wins over other containing names.
- Multiple case-insensitive exact matches are ambiguous.
- Multiple partial matches return non-zero, list the candidates, and never call
  native Worktrunk.
- No match passes the original target through unchanged.
- Worktree discovery failure passes the original command through unchanged.
- A local branch without a worktree is not considered.
- A detached worktree is not considered.
- Regex and glob metacharacters are treated literally.
- Arguments after the target survive resolution.
- Existing Bitbucket URL, picker, completion, lazy initialization, and native
  status behavior continue to pass.
