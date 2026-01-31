# Load dependency management functions
source ~/.config/fish/helpers/dependency_management.fish

# Convenience alias for quick dependency check
alias deps="check_and_install_dependencies"

# Homebrew shellenv (macOS, Homebrew installed via /opt/homebrew)
if test (uname) = Darwin
    if test -x /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
    end
else if test -x /home/linuxbrew/.linuxbrew/bin/brew
    # Optional: Homebrew on Linux
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# Check and install dependencies on first load
# Only run this check if we're in an interactive session
if status is-interactive
    show_welcome_banner
    check_and_install_dependencies
    show_missing_deps_reminder
end

# Aliases
alias dev="cd $HOME/Development"
alias dotfiles="cd $HOME/Development/Personal/dotfiles"
alias obsidian="cd $HOME/Development/Obsidian/Dev/.obsidian/plugins"
alias docs="cd $HOME/Documents"
alias downloads="cd $HOME/Downloads"
alias atlassian="cd $HOME/atlassian"
alias canvas="cd $HOME/atlassian/canvas"
#alias vim="nvim --listen /tmp/nvim-server.pipe"
#alias vi="vim"
#alias oldvi="vi"
alias c="clear"
alias nap="/Users/hosman/go/bin/nap"
alias rovo="acli rovodev"

if test -x /opt/homebrew/bin/fnm
    alias fnm="/opt/homebrew/bin/fnm"
end

# ls Aliases
alias ll="eza --group --group-directories-first --git --long --all --sort=type"

# fzf with preview - use 'fzfp' for fzf with bat preview
if type -q bat
    alias fzfp="fzf --preview 'bat --color=always --style=header,grid --line-range :500 -- {}'"
end

# Git Aliases
alias gl="git pull"
alias glorigin="glbranch main"
alias gp="git push --no-verify -f"
alias gcm="git commit --message"
alias gcammend="git commit --amend --no-edit"
alias gb="git branch"
alias gcurrent="git branch --show-current"
alias gs="git status"
alias gco="git checkout"
alias glog="git log --oneline --graph --decorate --all"

# Atlassian Dev variables
export ATLASSIAN_VPN_MFA_DEFAULT="push"
export ATLASSIAN_VPN_SERVER_DEFAULT="APSE2 Sydney (managed)"
set PATH $PATH $HOME/.jenv/bin # Configuring for Jenv. Required for acra-mini

# Use VI mode
set -g fish_key_bindings fish_vi_key_bindings

# Emulates vim's cursor shape behavior
set fish_cursor_default block # Set the normal and visual mode cursors to a block 
set fish_cursor_insert line # Set the insert mode cursor to a line 
set fish_cursor_replace_one underscore # Set the replace mode cursors to an underscore 

# Created by `pipx` on 2024-04-14 22:38:46
set PATH $PATH /Users/hosman/.local/bin

# Ensure Rust is in local path
if test -f ~/.cargo/env.fish
    source ~/.cargo/env.fish
end

# ADD FNM to path
# Only initialize in interactive shells; non-interactive `fish -c` can't infer the shell in some environments.
if status is-interactive; and type -q fnm
    fnm env --use-on-cd | source
end

# Configure zoxide to replace `cd`
if type -q zoxide
    zoxide init --cmd cd fish | source
end

# Setup fzf keybindings (Ctrl-R for history search, etc.)
if type -q fzf
    fzf --fish | source
end

# Run Starship prompt
if type -q starship
    starship init fish | source
    export STARSHIP_CONFIG=~/.config/starship/starship.toml
end

# Config NAP (snippets Go app) to use nvim as editor
export EDITOR="nvim"

# Change LazyGit config directory
export XDG_CONFIG_HOME="$HOME/.config"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# proxmox-specific

