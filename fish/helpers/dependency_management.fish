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

# Detect package manager
function detect_package_manager
    # Check for system package managers first (Linux)
    if type -q apt-get
        echo "apt"
    else if type -q dnf
        echo "dnf"
    else if type -q pacman
        echo "pacman"
    else if type -q brew
        echo "brew"
    else
        echo "none"
    end
end

# Install packages based on package manager
function install_deps_via_package_manager
    set pkg_manager (detect_package_manager)
    set missing_deps $argv
    
    # Map package names for different package managers
    set apt_deps
    for dep in $missing_deps
        switch $dep
            case zoxide
                set -a apt_deps zoxide
            case eza
                set -a apt_deps eza
            case fzf
                set -a apt_deps fzf
            case starship
                echo "⚠️  starship: Install via: curl -sS https://starship.rs/install.sh | sh"
            case bat
                set -a apt_deps bat
            case '*'
                set -a apt_deps $dep
        end
    end
    
    switch $pkg_manager
        case apt
            echo "📦 Installing via apt-get: "(string join " " $apt_deps)
            if test (id -u) -eq 0
                apt-get update -qq && apt-get install -y $apt_deps
            else
                sudo apt-get update -qq && sudo apt-get install -y $apt_deps
            end
        case brew
            echo "📦 Installing via Homebrew: "(string join " " $missing_deps)
            brew install $missing_deps
        case dnf
            echo "📦 Installing via dnf: "(string join " " $apt_deps)
            if test (id -u) -eq 0
                dnf install -y $apt_deps
            else
                sudo dnf install -y $apt_deps
            end
        case pacman
            echo "📦 Installing via pacman: "(string join " " $apt_deps)
            if test (id -u) -eq 0
                pacman -S --noconfirm $apt_deps
            else
                sudo pacman -S --noconfirm $apt_deps
            end
        case none
            echo "❌ No package manager found (apt, dnf, pacman, or brew)"
            echo "Please install dependencies manually"
            return 1
    end
end

# Main function to check and install dependencies
function check_and_install_dependencies
    set missing_deps (check_missing_deps)
    
    # If there are missing dependencies, check for package manager and prompt for installation
    if test (count $missing_deps) -gt 0
        set pkg_manager (detect_package_manager)
        
        if test "$pkg_manager" = "none"
            echo "❌ No supported package manager found."
            echo "Please install: brew, apt-get, dnf, or pacman"
            echo "Missing: "(string join ", " $missing_deps)
            return 1
        end
        
        echo "🔍 Missing dependencies detected: "(string join ", " $missing_deps)
        echo "📦 Package manager: $pkg_manager"
        echo -n "Would you like to install them? [Y/n] "
        read -l response
        
        # Default to 'yes' if empty response or 'Y'/'y'
        if test -z "$response"; or string match -qi "y*" "$response"
            echo "📦 Installing missing dependencies..."
            
            if install_deps_via_package_manager $missing_deps
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
    echo " ╦ ╦╔═╗╔╦╗╦ ╦╔╗╔╔═╗"
    echo " ╠═╣╠═╣ ║║╚╦╝║║║╔═╝"
    echo " ╩ ╩╩ ╩═╩╝ ╩ ╝╚╝╚═╝"
    echo ""
    echo "🐟 Welcome to your fish shell configuration!"
    echo ""
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
