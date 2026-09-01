function __wt_custom_complete_wt
    set -l command_tokens (commandline --current-process --tokenize --cut-at-cursor)
    if test (count $command_tokens) -ge 2
        and test "$command_tokens[1]" = wt
        and test "$command_tokens[2]" = delete
        set command_tokens[2] remove
    end

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

function __wt_custom_complete_wt_command_position
    set -l command_tokens (commandline --current-process --tokenize --cut-at-cursor)
    test (count $command_tokens) -eq 1
end

complete --keep-order --no-files --command wt --arguments '(__wt_custom_complete_wt)'
complete --keep-order --no-files --command wt --condition __wt_custom_complete_wt_command_position --arguments delete --description 'Alias for remove'
