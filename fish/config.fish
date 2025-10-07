# Homebrew dependency management
function check_and_install_dependencies
    # Define list of required dependencies
    set dependencies zoxide eza fzf starship bat
    
    set missing_deps (check_missing_deps)
    
    # If there are missing dependencies, check for brew and prompt for installation
    if test (count $missing_deps) -gt 0
        # Check if brew is installed
        if not type -q brew
            echo "🍺 Homebrew is not installed or not in PATH."
            echo "Please install Homebrew first: https://brew.sh/"
            return 1
        end
        # Check if running as root (brew doesn't support root installation)
        if test (id -u) -eq 0
            echo "⚠️  Running as root detected. Homebrew cannot install packages as root."
            echo "💡 Switch to a non-root user to install dependencies:"
            echo "   su - your_username"
            echo "   # or create a new user if needed:"
            echo "   useradd -m -s /usr/bin/fish your_username"
            echo "   su - your_username"
            echo ""
            echo "🔍 Missing dependencies that would be installed: "(string join ", " $missing_deps)
            echo ""
            echo "💡 After switching users, the dependency check will run automatically."
            echo "   If you need to manually trigger it, run: check_and_install_dependencies"
            return 1
        end
        echo "🔍 Missing dependencies detected: "(string join ", " $missing_deps)
        echo -n "Would you like to install them via brew? [Y/n] "
        read -l response
        
        # Default to 'yes' if empty response or 'Y'/'y'
        if test -z "$response"; or string match -qi "y*" "$response"
            echo "📦 Installing missing dependencies..."
            echo "Running: brew install "(string join " " $missing_deps)
            
            if brew install $missing_deps
                echo "🎉 All dependencies installation complete!"
                echo ""
                echo "💡 To apply changes, you can:"
                echo "   • Restart your shell: exec fish"
                echo "   • Source your config: source ~/.config/fish/config.fish"
                echo "   • Or simply open a new terminal window"
            else
                echo "❌ Failed to install some dependencies."
                echo "💡 You may need to install them manually or check for errors above."
                return 1
            end
        else
            echo "⚠️  Skipping dependency installation. Some features may not work correctly."
        end
    end
end

# Helper function to check missing dependencies
function check_missing_deps
    set dependencies zoxide eza fzf starship bat
    set missing_deps
    
    for dep in $dependencies
        if not type -q $dep
            set -a missing_deps $dep
        end
    end
    
    echo $missing_deps
end

# Save functions so they're available in all sessions
funcsave check_and_install_dependencies >/dev/null 2>&1
funcsave check_missing_deps >/dev/null 2>&1

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
    # Show a brief welcome message for new users
    if test (count (check_missing_deps)) -gt 0; or test (id -u) -eq 0
        echo " ╦ ╦╔═╗╔╦╗╦ ╦╔╗╔╔═╗"
        echo " ╠═╣╠═╣ ║║╚╦╝║║║╔═╝"
        echo " ╩ ╩╩ ╩═╩╝ ╩ ╝╚╝╚═╝"
        echo ""
        echo "🐟 Welcome to your fish shell configuration!"
        echo ""
    end
    
    check_and_install_dependencies
    
    # If we still have missing deps after the check, show a reminder
    set remaining_missing (check_missing_deps)
    if test (count $remaining_missing) -gt 0
        echo ""
        echo "📝 Note: Some dependencies are still missing: "(string join ", " $remaining_missing)
        echo "💡 Some shell features may not work until these are installed."
    end
end

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
alias c="clear"
alias nap="/Users/hosman/go/bin/nap"
alias rovo="acli rovodev"

if test -x /opt/homebrew/bin/fnm
    alias fnm="/opt/homebrew/bin/fnm"
end

# ls Aliases
alias ll="eza --group --group-directories-first --git --long --all --sort=type"

## List files/dirs with tree view. Takes in single param to specify tree depth
function lt
    set -q argv[1]; or set argv[1] "."
    set -q argv[2]; or set argv[2] 1
    eza --group --header --group-directories-first --git --tree --level $argv[2] $argv[1]
end
funcsave lt >/dev/null 2>&1

## Pulls latest from remote version of the current branch
function glbranch
    set branch_name (git branch --show-current)
    if test -n "$argv[1]"
        set branch_name $argv[1]
    end

    set command "git pull origin $branch_name --no-rebase"

    echo "Executing: \"$command\""
    eval $command
end
funcsave glbranch >/dev/null 2>&1

# fzf Aliases
alias fzf="fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}'"

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
if type -q fnm
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
