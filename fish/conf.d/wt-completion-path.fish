set -l wt_custom_completion_dir (path normalize (status dirname)/../custom-completions)
if test -d "$wt_custom_completion_dir"
    if not contains -- "$wt_custom_completion_dir" $fish_complete_path
        set -g fish_complete_path "$wt_custom_completion_dir" $fish_complete_path
    end
end
