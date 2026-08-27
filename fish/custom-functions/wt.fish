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

    set -l native_args $argv
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
            echo "wt: atlas prflow returned an unsafe branch name: $branch" >&2
            return 1
        end

        set native_args switch "$branch" $argv[3..-1]
    end

    if not functions -q __worktrunk_native
        command "$worktrunk_bin" config shell init fish --cmd=__worktrunk_native | source
        set -l pipeline_status $pipestatus
        test $pipeline_status[1] -eq 0; or return $pipeline_status[1]
        test $pipeline_status[2] -eq 0; or return $pipeline_status[2]
    end

    __worktrunk_native $native_args
end
