function gswitch
    if test (count $argv) -ne 1
        echo "Usage: gswitch <branch-name>" >&2
        return 1
    end

    git switch -c "$argv[1]" origin/main
end
