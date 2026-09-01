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

function _wt_test_assert_log --argument-names expected path message
    set -l actual (_wt_test_logged_args "$path")
    _wt_test_assert_equal "$expected" "$actual" "$message"
end

function _wt_test_logged_args --argument-names path
    if not test -s "$path"
        return
    end
    string join '|' -- (string split \n -- (string trim (string collect < "$path")))
end

set -gx WT_TEST_GENERATED_INTEGRATION "$wt_test_tmp/generated-wt.fish"
printf '%s\n' \
    'function wt' \
    '    if test "$argv[1]" = --source' \
    '        cargo run --bin wt --quiet -- $argv[2..-1]' \
    '        return $status' \
    '    end' \
    '    printf "%s\n" $argv > "$WT_TEST_NATIVE_LOG"' \
    '    return $WT_TEST_NATIVE_STATUS' \
    'end' > "$WT_TEST_GENERATED_INTEGRATION"
printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$@" > "$WT_TEST_BINARY_LOG"' \
    'if [ "$1" = "config" ]; then' \
    '    /bin/cat "$WT_TEST_GENERATED_INTEGRATION"' \
    'fi' \
    'exit 0' > "$wt_test_tmp/wt"
chmod +x "$wt_test_tmp/wt"
set -gx PATH "$wt_test_tmp" $PATH

set -g WT_TEST_NATIVE_LOG "$wt_test_tmp/native.log"
set -g WT_TEST_ATLAS_LOG "$wt_test_tmp/atlas.log"
set -g WT_TEST_CARGO_LOG "$wt_test_tmp/cargo.log"
set -gx WT_TEST_BINARY_LOG "$wt_test_tmp/binary.log"
set -g WT_TEST_ERROR_LOG "$wt_test_tmp/error.log"
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

function cargo
    printf '%s\n' $argv > "$WT_TEST_CARGO_LOG"
end

source (status dirname)/../custom-functions/wt.fish

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

set -l match_output (__wt_match_local_worktree smart feature/CNS-123-smart-switch feature/unrelated)
set -l match_status $status
_wt_test_assert_status 0 $match_status 'unique local-worktree substring should resolve'
_wt_test_assert_equal 'feature/CNS-123-smart-switch' "$match_output" 'unique substring should return the canonical branch'

set match_output (__wt_match_local_worktree cns-123 feature/CNS-123-smart-switch feature/unrelated)
set match_status $status
_wt_test_assert_status 0 $match_status 'local-worktree matching should be case-insensitive'
_wt_test_assert_equal 'feature/CNS-123-smart-switch' "$match_output" 'case-insensitive matching should preserve canonical casing'

set match_output (__wt_match_local_worktree 'a+b' feature/aaab feature/literal-a+b)
set match_status $status
_wt_test_assert_status 0 $match_status 'worktree target metacharacters should be literal'
_wt_test_assert_equal 'feature/literal-a+b' "$match_output" 'literal matching should not treat plus as a regex operator'

set match_output (__wt_match_local_worktree 'a*' feature/abcd feature/unrelated)
set match_status $status
_wt_test_assert_status 1 $match_status 'worktree target glob characters should be literal'
_wt_test_assert_equal '' "$match_output" 'literal glob characters should not create false matches'

set match_output (__wt_match_local_worktree feature/foo feature/foo feature/foo-experiment)
set match_status $status
_wt_test_assert_status 0 $match_status 'an exact worktree name should beat partial matches'
_wt_test_assert_equal 'feature/foo' "$match_output" 'exact precedence should return only the exact branch'

set match_output (__wt_match_local_worktree FOO feature/Foo feature/foo)
set match_status $status
_wt_test_assert_status 2 $match_status 'multiple case-insensitive exact names should be ambiguous'
_wt_test_assert_equal 'feature/Foo|feature/foo' (string join '|' $match_output) 'ambiguous exact names should be sorted'

set match_output (__wt_match_local_worktree smart z-smart a-smart m-smart)
set match_status $status
_wt_test_assert_status 2 $match_status 'multiple partial worktree matches should be ambiguous'
_wt_test_assert_equal 'a-smart|m-smart|z-smart' (string join '|' $match_output) 'ambiguous partial names should be sorted'

set -l parser_output (__wt_single_remove_target_index cns-456 --force)
set -l parser_status $status
_wt_test_assert_status 0 $parser_status 'remove target before trailing boolean option should be classified'
_wt_test_assert_equal '1' "$parser_output" 'remove target before trailing boolean option should return its index'

set parser_output (__wt_single_remove_target_index --force cns-456 -D)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'remove target between boolean options should be classified'
_wt_test_assert_equal '2' "$parser_output" 'remove target between boolean options should return its index'

set parser_output (__wt_single_remove_target_index --format json cns-456)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'remove target after separate format value should be classified'
_wt_test_assert_equal '3' "$parser_output" 'separate format value should count toward target index'

set parser_output (__wt_single_remove_target_index cns-456 --format=json)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'remove target before inline format option should be classified'
_wt_test_assert_equal '1' "$parser_output" 'inline format option should not affect target index'

set parser_output (__wt_single_remove_target_index -Dfv cns-456)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'boolean short option cluster should be classified'
_wt_test_assert_equal '2' "$parser_output" 'short option cluster should count toward target index'

set parser_output (__wt_single_remove_target_index -- -leading-target)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'double dash should allow option-like remove target'
_wt_test_assert_equal '2' "$parser_output" 'double dash should count toward target index'

set parser_output (__wt_single_remove_target_index)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'remove with no arguments should have no target'
_wt_test_assert_equal '' "$parser_output" 'remove with no arguments should produce no parser output'

set parser_output (__wt_single_remove_target_index one two)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'remove with multiple targets should be rejected'
_wt_test_assert_equal '' "$parser_output" 'multiple remove targets should produce no parser output'

set parser_output (__wt_single_remove_target_index -C /tmp one)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'separate repository context option should be rejected'
_wt_test_assert_equal '' "$parser_output" 'separate repository context option should produce no parser output'

set parser_output (__wt_single_remove_target_index -vC/tmp one)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'clustered repository context option should be rejected'
_wt_test_assert_equal '' "$parser_output" 'clustered repository context option should produce no parser output'

set parser_output (__wt_single_remove_target_index --unknown one)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'unknown remove option should be rejected'
_wt_test_assert_equal '' "$parser_output" 'unknown remove option should produce no parser output'

set parser_output (__wt_single_remove_target_index smart --help)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'help after a remove target should bypass smart classification'
_wt_test_assert_equal '' "$parser_output" 'help after a remove target should produce no parser output'

set parser_output (__wt_single_remove_target_index -h smart)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'short help before a remove target should bypass smart classification'
_wt_test_assert_equal '' "$parser_output" 'short help before a remove target should produce no parser output'

set parser_output (__wt_single_remove_target_index -vh smart)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'clustered short help before a remove target should bypass smart classification'
_wt_test_assert_equal '' "$parser_output" 'clustered short help before a remove target should produce no parser output'

set parser_output (__wt_single_remove_target_index -- -h)
set parser_status $status
_wt_test_assert_status 0 $parser_status 'double dash should preserve short help-looking target'
_wt_test_assert_equal '2' "$parser_output" 'double dash should return short help-looking target index'

set parser_output (__wt_single_remove_target_index --format)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'format option without a value should be rejected'
_wt_test_assert_equal '' "$parser_output" 'format option without a value should produce no parser output'

set parser_output (__wt_single_remove_target_index --config)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'config option without a value should be rejected'
_wt_test_assert_equal '' "$parser_output" 'config option without a value should produce no parser output'

set parser_output (__wt_single_remove_target_index --config-set)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'config-set option without a value should be rejected'
_wt_test_assert_equal '' "$parser_output" 'config-set option without a value should produce no parser output'

set parser_output (__wt_single_remove_target_index --format --force smart)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'format option followed by another option should be rejected'
_wt_test_assert_equal '' "$parser_output" 'format option followed by another option should produce no parser output'

set parser_output (__wt_single_remove_target_index --config -- smart)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'config option followed by double dash should be rejected'
_wt_test_assert_equal '' "$parser_output" 'config option followed by double dash should produce no parser output'

set parser_output (__wt_single_remove_target_index --config-set -- smart)
set parser_status $status
_wt_test_assert_status 1 $parser_status 'config-set option followed by double dash should be rejected'
_wt_test_assert_equal '' "$parser_output" 'config-set option followed by double dash should produce no parser output'

set parser_output (__wt_single_remove_target_index "")
set parser_status $status
_wt_test_assert_status 1 $parser_status 'empty remove target should be rejected'
_wt_test_assert_equal '' "$parser_output" 'empty remove target should produce no parser output'

set parser_output (__wt_single_remove_target_index -- "")
set parser_status $status
_wt_test_assert_status 1 $parser_status 'empty remove target after double dash should be rejected'
_wt_test_assert_equal '' "$parser_output" 'empty remove target after double dash should produce no parser output'

set -l smart_repo "$wt_test_tmp/smart-switch-repo"
command git init --quiet --initial-branch=main "$smart_repo"
command git -C "$smart_repo" -c user.name=Test -c user.email=test@example.com commit --quiet --allow-empty -m initial

for branch in feature/CNS-123-smart-switch feature/CNS-456-smart-search feature/CNS-123-smart-switch-followup feature/literal-a+b
    command git -C "$smart_repo" branch "$branch"
    set -l worktree_name (string replace --all / - "$branch")
    command git -C "$smart_repo" worktree add --quiet "$wt_test_tmp/$worktree_name" "$branch"
end

command git -C "$smart_repo" branch feature/CNS-999-no-worktree
set -l detached_worktree "$wt_test_tmp/detached-worktree"
command git -C "$smart_repo" worktree add --quiet --detach "$detached_worktree" HEAD
set -l path_collision_branch "feature$detached_worktree"
command git -C "$smart_repo" branch "$path_collision_branch"
command git -C "$smart_repo" worktree add --quiet "$wt_test_tmp/path-collision-branch" "$path_collision_branch"

pushd "$smart_repo" >/dev/null
set -l discovered (__wt_local_worktree_branches)
set -l discovery_status $status
popd >/dev/null

_wt_test_assert_status 0 $discovery_status 'local worktree discovery should succeed inside a repository'
set -l expected_discovered (printf '%s\n' feature/CNS-123-smart-switch feature/CNS-123-smart-switch-followup feature/CNS-456-smart-search feature/literal-a+b "$path_collision_branch" main | env LC_ALL=C sort -u)
_wt_test_assert_equal (string join '|' $expected_discovered) (string join '|' $discovered) 'discovery should return sorted checked-out branches only'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch cns-456 --no-hooks
set -l call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'unique smart worktree switch should succeed'
_wt_test_assert_log 'switch|feature/CNS-456-smart-search|--no-hooks' "$WT_TEST_NATIVE_LOG" 'smart switch should pass the canonical branch and trailing arguments'

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

command rm -f "$WT_TEST_NATIVE_LOG" "$WT_TEST_ERROR_LOG"
pushd "$smart_repo" >/dev/null
wt switch smart 2>"$WT_TEST_ERROR_LOG"
set call_status $status
popd >/dev/null
_wt_test_assert_status 1 $call_status 'ambiguous smart switch should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'ambiguous smart switch should not call Worktrunk'
_wt_test_assert_log "wt: 'smart' matches multiple local worktrees:|  feature/CNS-123-smart-switch|  feature/CNS-123-smart-switch-followup|  feature/CNS-456-smart-search|wt: retry with a more specific name" "$WT_TEST_ERROR_LOG" 'ambiguous smart switch should list sorted candidates and guidance'

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

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch cns-456 --create
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'trailing create should remain native for a unique fuzzy collision'
_wt_test_assert_log 'switch|cns-456|--create' "$WT_TEST_NATIVE_LOG" 'trailing create should not rewrite a unique target'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch smart --create
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'trailing create should remain native for an ambiguous fuzzy collision'
_wt_test_assert_log 'switch|smart|--create' "$WT_TEST_NATIVE_LOG" 'trailing create should not reject an ambiguous target'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch cns-456 -C "$wt_test_tmp"
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'trailing repository context should remain native'
_wt_test_assert_log "switch|cns-456|-C|$wt_test_tmp" "$WT_TEST_NATIVE_LOG" 'trailing repository context should not use the current repository for smart resolution'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch cns-456 -cv
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'clustered create options should remain native'
_wt_test_assert_log 'switch|cns-456|-cv' "$WT_TEST_NATIVE_LOG" 'clustered create options should not rewrite the target'

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch cns-456 "-vC$wt_test_tmp"
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'clustered repository context should remain native'
_wt_test_assert_log "switch|cns-456|-vC$wt_test_tmp" "$WT_TEST_NATIVE_LOG" 'clustered repository context should not use the current repository for smart resolution'

for attached_value_option in -xcode -vxcode -bcurrent
    command rm -f "$WT_TEST_NATIVE_LOG"
    pushd "$smart_repo" >/dev/null
    wt switch cns-456 "$attached_value_option"
    set call_status $status
    popd >/dev/null
    _wt_test_assert_status 0 $call_status "attached option value $attached_value_option should allow smart resolution"
    _wt_test_assert_log "switch|feature/CNS-456-smart-search|$attached_value_option" "$WT_TEST_NATIVE_LOG" "characters in the $attached_value_option value should not be treated as flags"
end

command rm -f "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch "$detached_worktree"
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'registered worktree paths should remain native'
_wt_test_assert_log "switch|$detached_worktree" "$WT_TEST_NATIVE_LOG" 'a path colliding with a branch substring should not be rewritten'

for shortcut in '@' '^' '-' 'pr:17' 'mr:18'
    command rm -f "$WT_TEST_NATIVE_LOG"
    pushd "$smart_repo" >/dev/null
    wt switch "$shortcut"
    set call_status $status
    popd >/dev/null
    _wt_test_assert_status 0 $call_status "native shortcut $shortcut should succeed"
    _wt_test_assert_log "switch|$shortcut" "$WT_TEST_NATIVE_LOG" "native shortcut $shortcut should pass through unchanged"
end

command rm -f "$WT_TEST_BINARY_LOG" "$WT_TEST_NATIVE_LOG"
set -gx COMPLETE fish
pushd "$smart_repo" >/dev/null
wt switch cns-456
set call_status $status
popd >/dev/null
set -e COMPLETE
_wt_test_assert_status 0 $call_status 'completion mode should succeed'
_wt_test_assert_log 'switch|cns-456' "$WT_TEST_BINARY_LOG" 'completion mode should bypass smart resolution and call the binary directly'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'completion mode should not call the generated native function'

set -l bitbucket_url 'https://bitbucket.org/atlassian/canvas/pull-requests/123'
set -g WT_TEST_ATLAS_OUTPUT 'feature/bitbucket-switch'
wt switch "$bitbucket_url" --no-hooks
set call_status $status
_wt_test_assert_status 0 $call_status 'Bitbucket switch should succeed'
_wt_test_assert_log "prflow|branch|$bitbucket_url" "$WT_TEST_ATLAS_LOG" 'Bitbucket URL should be passed to atlas prflow'
_wt_test_assert_log 'switch|feature/bitbucket-switch|--no-hooks' "$WT_TEST_NATIVE_LOG" 'resolved branch and trailing flags should reach Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -l mixed_case_url 'HTTPS://Bitbucket.org/atlassian/canvas/pull-requests/124'
set -g WT_TEST_ATLAS_OUTPUT 'feature/mixed-case-url'
wt switch "$mixed_case_url"
set call_status $status
_wt_test_assert_status 0 $call_status 'mixed-case Bitbucket URL should succeed'
_wt_test_assert_log "prflow|branch|$mixed_case_url" "$WT_TEST_ATLAS_LOG" 'mixed-case Bitbucket URL should be passed to atlas prflow'
_wt_test_assert_log 'switch|feature/mixed-case-url' "$WT_TEST_NATIVE_LOG" 'mixed-case URL should resolve before Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
pushd "$smart_repo" >/dev/null
wt switch guaranteed-unmatched-target
set call_status $status
popd >/dev/null
_wt_test_assert_status 0 $call_status 'ordinary branch switch should succeed'
_wt_test_assert_log '' "$WT_TEST_ATLAS_LOG" 'ordinary branch switch should not call atlas'
_wt_test_assert_log 'switch|guaranteed-unmatched-target' "$WT_TEST_NATIVE_LOG" 'ordinary branch switch should pass through unchanged'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -l github_url 'https://github.com/example/project/pull/456'
wt switch "$github_url"
set call_status $status
_wt_test_assert_status 0 $call_status 'GitHub URL switch should remain native'
_wt_test_assert_log '' "$WT_TEST_ATLAS_LOG" 'GitHub URL switch should not call atlas'
_wt_test_assert_log "switch|$github_url" "$WT_TEST_NATIVE_LOG" 'GitHub URL switch should pass through unchanged'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
wt switch
set call_status $status
_wt_test_assert_status 0 $call_status 'picker invocation should succeed'
_wt_test_assert_log '' "$WT_TEST_ATLAS_LOG" 'picker invocation should not call atlas'
_wt_test_assert_log 'switch' "$WT_TEST_NATIVE_LOG" 'picker invocation should pass through unchanged'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_NATIVE_STATUS 23
wt list
set call_status $status
_wt_test_assert_status 23 $call_status 'native Worktrunk failure should pass through'
_wt_test_assert_log 'list' "$WT_TEST_NATIVE_LOG" 'non-switch commands should pass through unchanged'
set -g WT_TEST_NATIVE_STATUS 0

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_ATLAS_STATUS 42
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 42 $call_status 'atlas failure status should pass through'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'atlas failure should not call Worktrunk'
set -g WT_TEST_ATLAS_STATUS 0

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -e WT_TEST_ATLAS_OUTPUT
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 1 $call_status 'empty resolver output should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'empty resolver output should not call Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_ATLAS_OUTPUT feature/one feature/two
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 1 $call_status 'multi-line resolver output should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'multi-line resolver output should not call Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_ATLAS_OUTPUT '--execute=touch-pwned'
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 1 $call_status 'option-like resolver output should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'option-like resolver output should not call Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -g WT_TEST_ATLAS_OUTPUT '@'
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 1 $call_status 'reserved Worktrunk shortcut output should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'reserved shortcut output should not call Worktrunk'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG"
set -l ref_test_repo "$wt_test_tmp/ref-validation"
command git init --quiet --initial-branch=main "$ref_test_repo"
command git -C "$ref_test_repo" -c user.name=Test -c user.email=test@example.com commit --quiet --allow-empty -m initial
command git -C "$ref_test_repo" switch --quiet --create previous
command git -C "$ref_test_repo" switch --quiet main
set -g WT_TEST_ATLAS_OUTPUT '@{-1}'
pushd "$ref_test_repo" >/dev/null
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
popd >/dev/null
_wt_test_assert_status 1 $call_status 'checkout-history syntax from resolver should fail'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'checkout-history syntax should not call Worktrunk'

command rm -f "$WT_TEST_BINARY_LOG" "$WT_TEST_NATIVE_LOG"
functions --erase __worktrunk_native
wt list
set call_status $status
_wt_test_assert_status 0 $call_status 'lazy native initialization should succeed'
_wt_test_assert_log 'config|shell|init|fish' "$WT_TEST_BINARY_LOG" 'first native call should initialize Worktrunk under its default command name'
_wt_test_assert_log 'list' "$WT_TEST_NATIVE_LOG" 'initialized native function should receive arguments'

command rm -f "$WT_TEST_CARGO_LOG"
wt --source list
set call_status $status
_wt_test_assert_status 0 $call_status 'native source mode should succeed'
_wt_test_assert_log 'run|--bin|wt|--quiet|--|list' "$WT_TEST_CARGO_LOG" 'source mode should retain the Worktrunk Cargo binary name'

command rm -f "$WT_TEST_ATLAS_LOG" "$WT_TEST_NATIVE_LOG" "$WT_TEST_BINARY_LOG"
functions --erase atlas
functions --erase __worktrunk_native
set -gx PATH "$wt_test_tmp"
wt switch "$bitbucket_url" >/dev/null 2>/dev/null
set call_status $status
_wt_test_assert_status 127 $call_status 'missing atlas should fail with command-not-found status'
_wt_test_assert_log '' "$WT_TEST_NATIVE_LOG" 'missing atlas should not call Worktrunk'
_wt_test_assert_log '' "$WT_TEST_BINARY_LOG" 'missing atlas should not initialize Worktrunk'
set -gx PATH "$wt_test_tmp" $wt_test_original_path

if test $wt_test_failures -gt 0
    echo "$wt_test_failures test(s) failed" >&2
    exit 1
end

echo 'All wt Fish tests passed'
