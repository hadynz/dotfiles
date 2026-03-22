function glbranch
    set branch_name (git branch --show-current)
    if test -n "$argv[1]"
        set branch_name $argv[1]
    end

    set command "git pull origin $branch_name --no-rebase"

    echo "Executing: \"$command\""
    eval $command
end
