# Homebrew dependency management functions

# Helper function to check missing dependencies
function check_missing_deps
    set dependencies zoxide eza fzf starship bat
    set missing_deps
    
    for dep in $dependencies
        if not type -q $dep
            set -a missing_deps $dep
        end
    end
    
    # Only output if there are actually missing dependencies
    if test (count $missing_deps) -gt 0
        echo $missing_deps
    end
end

# Main function to check and install dependencies
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

# Show welcome banner for new users
function show_welcome_banner
    if test (count (check_missing_deps)) -gt 0
        echo " ╦ ╦╔═╗╔╦╗╦ ╦╔╗╔╔═╗"
        echo " ╠═╣╠═╣ ║║╚╦╝║║║╔═╝"
        echo " ╩ ╩╩ ╩═╩╝ ╩ ╝╚╝╚═╝"
        echo ""
        echo "🐟 Welcome to your fish shell configuration!"
        echo ""
    end
end

# Show reminder for remaining missing dependencies
function show_missing_deps_reminder
    set remaining_missing (check_missing_deps)
    if test (count $remaining_missing) -gt 0
        echo ""
        echo "📝 Note: Some dependencies are still missing: "(string join ", " $remaining_missing)
        echo "💡 Some shell features may not work until these are installed."
    end
end