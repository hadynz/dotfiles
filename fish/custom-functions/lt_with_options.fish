function lt_with_options
  # Default level variable to 2 if none provided
  set -q argv[1]; or set argv[1] 2
  eza --group --header --group-directories-first --git --tree --level $argv[1]
end
