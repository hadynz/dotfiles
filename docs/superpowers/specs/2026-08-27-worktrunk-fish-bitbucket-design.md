# Worktrunk Fish and Bitbucket integration

## Goal

Make Worktrunk the primary interactive worktree interface in Fish while keeping its configuration in dotfiles. The workflow should support:

- `wt create <branch>` to create a worktree from a freshly fetched `origin/main` and enter it.
- `wt switch <worktree-or-branch>` with unchanged native Worktrunk behavior.
- `wt switch <Bitbucket-PR-URL>` to resolve the PR's source branch and enter its worktree.
- Native `wt switch` picker and `Alt-x` removal behavior without modification.

## Configuration and installation

Add `worktrunk/config.toml` to the dotfiles repository. The existing setup script will expose Worktrunk as a selectable component and use its standard config-directory linking behavior to link the tracked directory at `~/.config/worktrunk`.

The config will define a personal Worktrunk alias named `create`. It will:

1. Fetch `origin` so the local `origin/main` remote-tracking ref is current.
2. Stop without creating anything if the fetch fails.
3. Run `wt switch --create <arguments> --base origin/main`.

Worktrunk aliases preserve the parent shell's directory change when they invoke `wt switch`, so successful creation ends inside the new worktree. Positional arguments are forwarded through Worktrunk's shell-escaped `{{ args }}` template value.

## Fish dispatch

Worktrunk resolves built-in commands before configured aliases, so an alias cannot override `switch`. The tracked `fish/functions/wt.fish` function will instead act as a narrow dispatcher.

On first use, the function will load Worktrunk's generated Fish shell integration under a private function name and point it at the real `wt` binary. This private function remains responsible for directive files, directory changes, exit statuses, and `--execute` behavior.

The public `wt` function will inspect only the common form `wt switch <target>`:

- If `<target>` starts with an HTTP or HTTPS Bitbucket Cloud PR URL shaped like `bitbucket.org/<workspace>/<repo>/pull-requests/<number>`, call `atlas prflow branch <target>`.
- Require `atlas` to be installed and require the resolver to return one non-empty branch name.
- Pass that branch and any arguments after the URL to the private native integration as `switch <branch> ...`.
- For every other invocation, pass all arguments unchanged to the private native integration.

This keeps `wt`, `wt switch`, `wt list`, `wt remove`, configured aliases, the interactive picker, global options, help, and completion behavior native unless the exact Bitbucket URL case is detected.

The first version intentionally targets Bitbucket Cloud URLs. Bitbucket Data Center URL formats and fork PRs whose source branch is not fetchable from a configured remote are outside scope. In those cases, the resulting Worktrunk error should remain visible and no fallback branch should be guessed.

## Error handling

The wrapper will return a non-zero status and avoid calling Worktrunk when:

- `atlas` is unavailable.
- `atlas prflow branch` fails.
- The resolver returns no branch or more than one non-empty output line.

Native Worktrunk errors and statuses pass through unchanged. A failed `git fetch origin` aborts `wt create`; it must not silently create from a stale base.

## Verification

Automated checks will avoid creating or removing real worktrees:

- Validate Fish syntax for the wrapper.
- Validate `worktrunk/config.toml` with the installed Worktrunk binary.
- Use `wt config alias dry-run create -- <sample-branch>` to confirm the rendered create command.
- Exercise the Fish dispatcher with stubbed `atlas` and native Worktrunk functions, covering Bitbucket URL resolution, argument forwarding, ordinary branch switching, picker invocation, resolver failure, missing/empty output, and multi-line output.
- Run the setup script in dry-run mode to confirm Worktrunk participates in normal component installation and linking.

Manual verification may then use a known Bitbucket PR URL to confirm that the shell enters the selected worktree. No removal command will run as part of verification.
