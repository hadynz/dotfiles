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

set -l bitbucket_url 'https://bitbucket.org/atlassian/canvas/pull-requests/123'
set -g WT_TEST_ATLAS_OUTPUT 'feature/bitbucket-switch'
wt switch "$bitbucket_url" --no-hooks
set -l call_status $status
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
wt switch feature/local
set call_status $status
_wt_test_assert_status 0 $call_status 'ordinary branch switch should succeed'
_wt_test_assert_log '' "$WT_TEST_ATLAS_LOG" 'ordinary branch switch should not call atlas'
_wt_test_assert_log 'switch|feature/local' "$WT_TEST_NATIVE_LOG" 'ordinary branch switch should pass through unchanged'

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
