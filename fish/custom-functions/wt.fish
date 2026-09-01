# Worktrunk shell integration for Fish with Bitbucket Cloud PR URL support.
# Native shell integration is loaded as __worktrunk_native so this public
# function can resolve Bitbucket PRs before delegating to Worktrunk.

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
        printf '%s\n' $branches | env LC_ALL=C sort -u
    end
end

# Return success when the target resolves to a registered local worktree path.
function __wt_is_local_worktree_path --argument-names target
    set -l target_path "$target"
    if test "$target" = '~'
        set target_path "$HOME"
    else if string match --quiet --regex '^~/' -- "$target"
        set target_path (string replace --regex '^~' "$HOME" -- "$target")
    end
    set -l resolved_target (path resolve -- "$target_path")

    set -l porcelain (command git worktree list --porcelain 2>/dev/null)
    test $status -eq 0; or return 1

    for line in $porcelain
        if string match --quiet --regex '^worktree ' -- "$line"
            set -l worktree_path (string replace 'worktree ' '' -- "$line")
            if test "$resolved_target" = (path resolve -- "$worktree_path")
                return 0
            end
        end
    end

    return 1
end

# Print matching canonical branch names.
# Status 0: one match; 1: no match; 2: ambiguous.
function __wt_match_local_worktree --argument-names target
    set -l branches $argv[2..-1]
    set -l matches
    set -l target_pattern (string escape --style=regex -- "$target")
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
        printf '%s\n' $exact_matches | env LC_ALL=C sort -f
        return 2
    end

    for branch in $branches
        if string match --ignore-case --quiet --regex -- "$target_pattern" "$branch"
            set -a matches "$branch"
        end
    end

    if test (count $matches) -gt 1
        set matches (printf '%s\n' $matches | env LC_ALL=C sort -f)
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

# Return success when trailing switch arguments require native target handling.
function __wt_switch_bypasses_smart_match
    set -l skip_next false
    for arg in $argv
        if test "$skip_next" = true
            set skip_next false
            continue
        end

        if test "$arg" = --
            break
        end

        switch "$arg"
            case --create
                return 0
            case --base --execute --format --config --config-set
                set skip_next true
                continue
            case '--base=*' '--execute=*' '--format=*' '--config=*' '--config-set=*'
                continue
            case '--*'
                continue
            case '-*'
                set -l short_options (string sub --start 2 -- "$arg")
                set -l option_index 0
                for short_option in (string split '' -- "$short_options")
                    set option_index (math $option_index + 1)
                    switch "$short_option"
                        case c C
                            return 0
                        case b x
                            if test $option_index -eq (string length -- "$short_options")
                                set skip_next true
                            end
                            break
                    end
                end
        end
    end

    return 1
end

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
            if test -z "$arg"; or string match --quiet -- '-*' "$arg"
                return 1
            end
            set skip_next false
            continue
        end

        if test -z "$arg"
            return 1
        end

        if test "$positional_only" = true
            set -a target_indexes $argument_index
            continue
        end

        if test "$arg" = --
            set positional_only true
            continue
        end

        switch "$arg"
            case --format --config --config-set
                set skip_next true
            case '--format=*' '--config=*' '--config-set=*'
            case --help
                return 1
            case --no-delete-branch --force-delete --foreground --reap --force --no-hooks --verbose --yes
            case '--*'
                return 1
            case '-*'
                set -l short_options (string sub --start 2 -- "$arg")
                if test -z "$short_options"
                    return 1
                end

                for short_option in (string split '' -- "$short_options")
                    switch "$short_option"
                        case D f v y
                        case h
                            return 1
                        case C '*'
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

function __wt_complete_command_position
    set -l command_tokens (commandline --current-process --tokenize --cut-at-cursor)
    test (count $command_tokens) -eq 1
end

function __wt_complete_delete_condition
    set -l command_tokens (commandline --current-process --tokenize --cut-at-cursor)
    if test (count $command_tokens) -lt 2
        return 1
    end
    if test "$command_tokens[1]" != wt
        return 1
    end
    if test "$command_tokens[2]" != delete
        return 1
    end
end

function __wt_complete_delete
    __wt_complete_delete_condition; or return 1

    set -l command_tokens (commandline --current-process --tokenize --cut-at-cursor)

    set command_tokens[2] remove
    set -l current_token (commandline --current-token)
    set -l worktrunk_bin "$WORKTRUNK_BIN"
    if test -z "$worktrunk_bin"
        set worktrunk_bin (type -P wt 2>/dev/null)
    end
    if test -z "$worktrunk_bin"
        return 1
    end

    env COMPLETE=fish "$worktrunk_bin" -- $command_tokens "$current_token"
end

complete --keep-order --command wt --condition __wt_complete_command_position --arguments delete --description 'Alias for remove'
complete --keep-order --command wt --condition '__wt_complete_delete_condition' --arguments '(__wt_complete_delete)'

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

    if test (count $argv) -ge 2
        and test "$argv[1]" = switch
        and string match --ignore-case --quiet --regex '^https?://bitbucket\.org/[^/]+/[^/]+/pull-requests/[0-9]+([/?#].*)?$' -- "$argv[2]"

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

        set -l branch "$branches[1]"
        if test "$branch" = '@'
            or test "$branch" = '^'
            or not command git check-ref-format --branch "$branch" >/dev/null 2>&1
            or not command git check-ref-format "refs/heads/$branch" >/dev/null 2>&1
            echo "wt: atlas prflow returned an unsafe branch name: $branch" >&2
            return 1
        end

        set native_args switch "$branch" $argv[3..-1]
    else if test (count $argv) -ge 2
        and test "$argv[1]" = switch
        and test -n "$argv[2]"
        and not string match --quiet -- '-*' "$argv[2]"
        and not contains -- "$argv[2]" '@' '^'
        and not string match --ignore-case --quiet --regex '^https?://' -- "$argv[2]"
        and not __wt_switch_bypasses_smart_match $argv[3..-1]

        set -l worktree_matches (__wt_resolve_local_worktree_target "$argv[2]")
        set -l match_status $status
        if test $match_status -eq 0
            set native_args switch "$worktree_matches[1]" $argv[3..-1]
        else if test $match_status -eq 2
            __wt_report_ambiguous_local_worktrees "$argv[2]" $worktree_matches
            return 1
        end
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

    if not functions -q __worktrunk_native
        set -l integration (command "$worktrunk_bin" config shell init fish)
        set -l init_status $status
        test $init_status -eq 0; or return $init_status

        # Rename only the generated Fish function. Asking Worktrunk to generate
        # a different command name also changes `cargo run --bin wt`, which
        # breaks its developer-only --source mode.
        set -l private_integration (string replace --regex '^function wt$' 'function __worktrunk_native' -- $integration)
        set -l rename_status $status
        if test $rename_status -ne 0
            echo 'wt: could not find the generated Worktrunk Fish function' >&2
            return 1
        end

        printf '%s\n' $private_integration | source
        set -l source_status $pipestatus[2]
        test $source_status -eq 0; or return $source_status
    end

    __worktrunk_native $native_args
end
