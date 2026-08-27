function glbranch
    set branch_name (git branch --show-current)
    set mode --no-rebase

    for arg in $argv
        switch $arg
            case --rebase -r
                set mode --rebase
            case --merge -m
                set mode --no-rebase
            case '*'
                set branch_name $arg
        end
    end

    set command "git pull origin $branch_name $mode"

    echo "Executing: \"$command\""
    eval $command
end
