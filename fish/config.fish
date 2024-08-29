if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Add Brew to Path
eval "$(/opt/homebrew/bin/brew shellenv)"

# Aliases
alias dev="cd $HOME/Development"
alias dotfiles="cd $HOME/Development/Personal/dotfiles"
alias obsidian="cd $HOME/Development/Obsidian/Dev/.obsidian/plugins"
alias docs="cd $HOME/Documents"
alias downloads="cd $HOME/Downloads"
alias atlassian="cd $HOME/atlassian"
alias canvas="cd $HOME/atlassian/canvas"
alias vim="nvim --listen /tmp/nvim-server.pipe"
alias vi="vim"
alias oldvi="vi"
alias ll="ls -la"
alias c="clear"
alias nap="/Users/hosman/go/bin/nap"
alias fnm="/opt/homebrew/bin/fnm"

# Git Aliases
alias gl="git pull"
alias glorigin="git pull origin main --no-rebase"
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

# Use VI mode
set -g fish_key_bindings fish_vi_key_bindings

# Emulates vim's cursor shape behavior
set fish_cursor_default block # Set the normal and visual mode cursors to a block 
set fish_cursor_insert line # Set the insert mode cursor to a line 
set fish_cursor_replace_one underscore # Set the replace mode cursors to an underscore 

# Created by `pipx` on 2024-04-14 22:38:46
set PATH $PATH /Users/hosman/.local/bin

# Ensure Rust is in local path
source "$HOME/.cargo/env.fish"

# ADD FNM to path
source ~/.config/fish/conf.d/fnm.fish

# Configure zoxide to replace `cd`
zoxide init --cmd cd fish | source

# Run Starship prompt
starship init fish | source
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# Config NAP (snippets Go app) to use nvim as editor
export EDITOR="nvim"

# Change LazyGit config directory
export XDG_CONFIG_HOME="$HOME/.config"

