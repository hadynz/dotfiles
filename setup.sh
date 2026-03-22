#!/usr/bin/env bash

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Dry run mode
DRY_RUN=false

# Non-interactive mode (for testing/automation)
NON_INTERACTIVE=false
AUTO_SELECT_ALL=false

# Unstow mode
UNSTOW_MODE=false

# Component definitions
# Format: "display_name:brew_package:apt_package:binary_name:config_dir:is_cask"
# Note: "MANUAL" means requires special installation steps, "N/A" means not available
declare -a COMPONENTS=(
    "Fish Shell:fish:fish:fish:fish:0"
    "Neovim:neovim:MANUAL:nvim:nvim:0"
    "Tmux:tmux:tmux:tmux:tmux:0"
    "Lazygit:jesseduffield/lazygit/lazygit:lazygit:lazygit:lazygit:0"
    "Starship:starship:MANUAL:starship:starship:0"
    "Wezterm:wezterm:MANUAL:wezterm:wezterm:1"
    "VSCode:visual-studio-code:MANUAL:code:vscode:1"
    "Cursor:cursor:N/A:cursor:vscode:1"
)

# Fish shell dependencies (optional but recommended for full functionality)
declare -a FISH_DEPS=(
    "Eza (better ls):eza:eza:eza::0"
    "Bat (better cat):bat:bat:bat::0"
    "Fzf (fuzzy finder):fzf:fzf:fzf::0"
    "Zoxide (smart cd):zoxide:zoxide:zoxide::0"
    "Ripgrep (better grep):ripgrep:ripgrep:rg::0"
    "Fd (better find):fd:fd-find:fd::0"
)

# Track components that need manual installation
declare -a MANUAL_INSTALL_NEEDED=()

# Selected package manager
PACKAGE_MANAGER=""

# Selected components (will be populated by user)
declare -a SELECTED_COMPONENTS=()

# ============================================================================
# Utility Functions
# ============================================================================

print_header() {
    echo -e "\n${BOLD}${BLUE}==>${NC}${BOLD} $1${NC}"
}

print_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${CYAN}  →${NC} $1"
}

detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        *)          echo "unknown";;
    esac
}

# ============================================================================
# Package Manager Detection
# ============================================================================

detect_package_manager() {
    print_header "Detecting package manager"
    
    local OS=$(detect_os)
    
    # On Linux, prefer system package manager (especially for root)
    if [ "$OS" = "linux" ]; then
        if command -v apt-get &> /dev/null; then
            PACKAGE_MANAGER="apt"
            print_info "Using apt-get (Debian/Ubuntu)"
            return 0
        elif command -v dnf &> /dev/null; then
            PACKAGE_MANAGER="dnf"
            print_info "Using dnf (Fedora/RHEL)"
            print_warning "Note: This script is optimized for apt-get. dnf support is experimental."
            return 0
        elif command -v pacman &> /dev/null; then
            PACKAGE_MANAGER="pacman"
            print_info "Using pacman (Arch Linux)"
            print_warning "Note: This script is optimized for apt-get. pacman support is experimental."
            return 0
        fi
    fi
    
    # Fall back to Homebrew (macOS or Linux without system package manager)
    if command -v brew &> /dev/null; then
        PACKAGE_MANAGER="brew"
        local brew_version=$(brew --version | head -n1)
        print_info "Using Homebrew: $brew_version"
        return 0
    fi
    
    # No package manager found
    print_error "No supported package manager found!"
    echo ""
    if [ "$OS" = "macos" ]; then
        echo "Please install Homebrew:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
        echo "Expected to find apt-get, dnf, pacman, or brew, but none were found."
        echo "Please install one of these package managers first."
    fi
    echo ""
    exit 1
}

# ============================================================================
# Interactive Component Selection
# ============================================================================

select_components() {
    print_header "Select components to install"
    
    # Auto-select all in non-interactive mode
    if [ "$NON_INTERACTIVE" = true ] || [ "$AUTO_SELECT_ALL" = true ]; then
        SELECTED_COMPONENTS=("${COMPONENTS[@]}" "${FISH_DEPS[@]}")
        print_info "Auto-selected all components (${#SELECTED_COMPONENTS[@]} total)"
        return
    fi
    
    # Check if fzf is available for better UX
    if command -v fzf &> /dev/null; then
        select_components_fzf
    else
        select_components_simple
    fi
    
    # Ask about fish dependencies if fish is selected
    ask_about_fish_deps
}

select_components_fzf() {
    echo "Use TAB to select/deselect, ENTER to confirm"
    echo ""
    
    # Create options list
    local options=()
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary config_dir is_cask <<< "$component"
        options+=("$display_name")
    done
    
    # Use fzf for multi-select
    local selected=$(printf '%s\n' "${options[@]}" | \
        fzf --multi \
            --height=40% \
            --border \
            --prompt="Select components: " \
            --header="TAB to select | ENTER to confirm" \
            --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
            --preview='echo "Select the components you want to install"')
    
    if [ -z "$selected" ]; then
        print_warning "No components selected. Exiting."
        exit 0
    fi
    
    # Map selected display names back to components
    while IFS= read -r display_name; do
        for component in "${COMPONENTS[@]}"; do
            IFS=':' read -r comp_display brew_pkg apt_pkg binary config_dir is_cask <<< "$component"
            if [ "$comp_display" = "$display_name" ]; then
                SELECTED_COMPONENTS+=("$component")
                break
            fi
        done
    done <<< "$selected"
}

select_components_simple() {
    echo "Select components (y/n):"
    
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary config_dir is_cask <<< "$component"
        
        read -p "  Install $display_name? [y/N] " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SELECTED_COMPONENTS+=("$component")
            echo " ✓"
        else
            echo ""
        fi
    done
    
    if [ ${#SELECTED_COMPONENTS[@]} -eq 0 ]; then
        print_warning "No components selected. Exiting."
        exit 0
    fi
}

ask_about_fish_deps() {
    # Check if fish was selected
    local fish_selected=false
    for component in "${SELECTED_COMPONENTS[@]}"; do
        if [[ $component == "Fish Shell"* ]]; then
            fish_selected=true
            break
        fi
    done
    
    if [ "$fish_selected" = false ]; then
        return
    fi
    
    echo ""
    echo "Fish shell uses several optional tools for enhanced functionality:"
    echo "  • eza (better ls), bat (syntax highlighting), fzf (fuzzy finder)"
    echo "  • zoxide (smart cd), ripgrep (fast search), fd (fast find)"
    echo ""
    read -p "Install Fish shell dependencies? [Y/n] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Add all fish deps
        SELECTED_COMPONENTS+=("${FISH_DEPS[@]}")
        print_info "Added ${#FISH_DEPS[@]} fish dependencies"
    fi
}

# ============================================================================
# Dependency Check & Installation
# ============================================================================

install_package() {
    local package_name=$1
    local is_cask=$2
    
    case $PACKAGE_MANAGER in
        brew)
            if [ "$is_cask" = "1" ]; then
                brew install --cask "$package_name"
            else
                brew install "$package_name"
            fi
            ;;
        apt)
            # For apt, we need sudo if not root
            if [ "$EUID" -eq 0 ]; then
                apt-get update -qq && apt-get install -y "$package_name"
            else
                sudo apt-get update -qq && sudo apt-get install -y "$package_name"
            fi
            ;;
        dnf)
            if [ "$EUID" -eq 0 ]; then
                dnf install -y "$package_name"
            else
                sudo dnf install -y "$package_name"
            fi
            ;;
        pacman)
            if [ "$EUID" -eq 0 ]; then
                pacman -S --noconfirm "$package_name"
            else
                sudo pacman -S --noconfirm "$package_name"
            fi
            ;;
        *)
            print_error "Unknown package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

# ============================================================================
# Custom Installers (for components not available via package manager)
# Named install_<binary>_manual to match the convention in check_and_install_components
# ============================================================================

install_nvim_manual() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="arm64" ;;
        *)
            print_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac

    local tarball="nvim-linux-${arch}.tar.gz"
    local url="https://github.com/neovim/neovim/releases/latest/download/${tarball}"

    print_step "Downloading latest Neovim for ${arch}..."
    curl -fLo "/tmp/${tarball}" "$url" || { print_error "Download failed"; return 1; }

    print_step "Extracting to /opt/nvim..."
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf "/tmp/${tarball}" || { print_error "Extraction failed"; return 1; }
    sudo mv /opt/nvim-linux-${arch} /opt/nvim

    # Add to PATH via /usr/local/bin symlink
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

    rm -f "/tmp/${tarball}"
    print_info "Neovim installed: $(nvim --version | head -n1)"
}

install_starship_manual() {
    print_step "Installing Starship via official installer..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

check_and_install_components() {
    print_header "Checking and installing components"
    
    for component in "${SELECTED_COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary config_dir is_cask <<< "$component"
        
        echo ""
        print_step "Processing: $display_name"
        
        # Skip empty entries (from fish deps with no config_dir)
        if [ -z "$binary" ]; then
            continue
        fi
        
        # Select the correct package name based on package manager
        local package_name=""
        if [ "$PACKAGE_MANAGER" = "brew" ]; then
            package_name="$brew_pkg"
        else
            package_name="$apt_pkg"
        fi
        
        # Check if package is available for this package manager
        if [ "$package_name" = "N/A" ]; then
            print_warning "$display_name is not available via $PACKAGE_MANAGER"
            print_warning "You'll need to install it manually. Skipping..."
            continue
        fi
        
        # Check if package requires manual installation
        if [ "$package_name" = "MANUAL" ]; then
            # Attempt auto-install for known components
            if [ "$DRY_RUN" = true ]; then
                print_warning "[DRY RUN] Would install $display_name via custom installer"
            elif type "install_${binary}_manual" &>/dev/null; then
                print_step "Installing $display_name via custom installer..."
                if "install_${binary}_manual"; then
                    print_info "$display_name installed successfully"
                else
                    print_error "Failed to install $display_name"
                    MANUAL_INSTALL_NEEDED+=("$display_name")
                fi
            else
                print_warning "$display_name requires manual installation"
                MANUAL_INSTALL_NEEDED+=("$display_name")
            fi
            continue
        fi
        
        # Check if already installed
        if command -v "$binary" &> /dev/null; then
            local version=$($binary --version 2>/dev/null | head -n1 || echo "installed")
            print_info "$display_name already installed: $version"
        else
            # Install via package manager
            if [ "$DRY_RUN" = true ]; then
                print_warning "[DRY RUN] Would install: $package_name (via $PACKAGE_MANAGER)"
            else
                print_step "Installing $display_name via $PACKAGE_MANAGER..."
                if install_package "$package_name" "$is_cask"; then
                    print_info "$display_name installed successfully"
                else
                    print_error "Failed to install $display_name"
                fi
            fi
        fi
    done
}

# ============================================================================
# Link Configuration Files
# ============================================================================

link_configs() {
    print_header "Linking configuration files"
    
    local OS=$(detect_os)
    local DOTFILES_DIR=$(pwd)
    
    # Ensure ~/.config exists
    mkdir -p "$HOME/.config"
    
    for component in "${SELECTED_COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary config_dir is_cask <<< "$component"
        
        # Skip if no config directory (like fish deps)
        if [ -z "$config_dir" ]; then
            continue
        fi
        
        echo ""
        print_step "Linking $display_name configs"
        
        # Handle VSCode/Cursor specially (platform-specific paths)
        if [ "$config_dir" = "vscode" ]; then
            link_vscode_configs "$display_name" "$OS" "$DOTFILES_DIR"
        else
            # Regular link to ~/.config
            if [ -d "$DOTFILES_DIR/$config_dir" ]; then
                local target="$HOME/.config/$config_dir"
                
                if [ "$DRY_RUN" = true ]; then
                    print_warning "[DRY RUN] Would link: $config_dir → ~/.config/$config_dir"
                else
                    # Check if config already exists
                    if [ -e "$target" ] && [ ! -L "$target" ]; then
                        local backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"
                        if [ "$NON_INTERACTIVE" = true ]; then
                            print_step "Backing up existing $config_dir to ${backup_path##*/}"
                            mv "$target" "$backup_path"
                        else
                            print_warning "$target exists and is not a symlink"
                            read -p "  Back it up and replace with dotfiles link? [Y/n] " -n 1 -r
                            echo
                            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                                print_step "Backing up to ${backup_path##*/}"
                                mv "$target" "$backup_path"
                            else
                                print_warning "Skipping $display_name config linking"
                                continue
                            fi
                        fi
                    fi
                    
                    # Remove existing symlink if it exists
                    if [ -L "$target" ]; then
                        rm "$target"
                    fi
                    
                    # Create the symlink
                    ln -s "$DOTFILES_DIR/$config_dir" "$target"
                    
                    if [ -L "$target" ]; then
                        print_info "✓ $display_name configs linked"
                    else
                        print_error "Failed to link $display_name configs"
                    fi
                fi
            else
                print_warning "No config directory found for $display_name (expected: $config_dir/)"
            fi
        fi
    done
}

link_vscode_configs() {
    local app_name=$1
    local os=$2
    local dotfiles_dir=$3
    local target_dir=""
    
    case $os in
        macos)
            if [ "$app_name" = "VSCode" ]; then
                target_dir="$HOME/Library/Application Support/Code/User"
            else
                target_dir="$HOME/Library/Application Support/Cursor/User"
            fi
            ;;
        linux)
            if [ "$app_name" = "VSCode" ]; then
                target_dir="$HOME/.config/Code/User"
            else
                target_dir="$HOME/.config/Cursor/User"
            fi
            ;;
    esac
    
    if [ ! -d "$target_dir" ]; then
        print_warning "$app_name directory not found at: $target_dir"
        print_warning "Install $app_name first, then re-run this script"
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "[DRY RUN] Would link vscode configs to: $target_dir"
        return
    fi
    
    # Link individual files from vscode directory
    for file in "$dotfiles_dir/vscode"/*; do
        local filename=$(basename "$file")
        local target="$target_dir/$filename"
        
        # Skip if target exists and is not a symlink
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            print_warning "$filename exists (not overwriting)"
            continue
        fi
        
        # Remove existing symlink
        [ -L "$target" ] && rm "$target"
        
        # Create symlink
        ln -s "$file" "$target"
    done
    
    print_info "✓ $app_name configs linked"
}

# ============================================================================
# Fish Shell Setup
# ============================================================================

setup_fish_shell() {
    # Check if fish was selected
    local fish_selected=false
    for component in "${SELECTED_COMPONENTS[@]}"; do
        if [[ $component == Fish* ]]; then
            fish_selected=true
            break
        fi
    done
    
    if [ "$fish_selected" = false ]; then
        return
    fi
    
    print_header "Fish Shell Setup"
    
    local fish_path=$(which fish)
    local current_shell=$(basename "$SHELL")
    
    if [ "$current_shell" = "fish" ]; then
        print_info "Fish is already your default shell"
    elif [ "$NON_INTERACTIVE" = true ]; then
        echo ""
        print_info "Non-interactive mode: Skipping default shell change"
    else
        echo ""
        echo "Fish is installed but not your default shell."
        read -p "Would you like to set Fish as your default shell? [y/N] " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ "$DRY_RUN" = true ]; then
                print_warning "[DRY RUN] Would set fish as default shell"
            else
                # Add fish to /etc/shells if not already there
                if ! grep -q "$fish_path" /etc/shells; then
                    print_step "Adding fish to /etc/shells (requires sudo)"
                    echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
                fi
                
                # Change default shell
                print_step "Changing default shell to fish"
                chsh -s "$fish_path"
                print_info "Default shell changed to fish! Restart your terminal to apply."
            fi
        fi
    fi
    
    # On Linux, ensure fish launches from bash for environments that ignore
    # the login shell (e.g. lxc-attach, some Docker/container setups).
    if [ "$(detect_os)" = "linux" ]; then
        local bashrc="$HOME/.bashrc"
        local fish_exec_marker="# >>> dotfiles fish launcher >>>"
        
        if [ -f "$bashrc" ] && grep -q "$fish_exec_marker" "$bashrc"; then
            print_info "Fish launcher already configured in .bashrc"
        else
            if [ "$DRY_RUN" = true ]; then
                print_warning "[DRY RUN] Would add fish launcher to .bashrc"
            elif [ "$NON_INTERACTIVE" = true ]; then
                print_step "Adding fish launcher to .bashrc"
                add_fish_bashrc_launcher "$bashrc" "$fish_exec_marker"
            else
                echo ""
                echo "Some environments (e.g. lxc-attach, Docker) ignore the login shell."
                read -p "Add a fish launcher to .bashrc for these cases? [Y/n] " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    add_fish_bashrc_launcher "$bashrc" "$fish_exec_marker"
                fi
            fi
        fi
    fi
}

add_fish_bashrc_launcher() {
    local bashrc="$1"
    local marker="$2"
    
    cat >> "$bashrc" << 'FISH_LAUNCHER'

# >>> dotfiles fish launcher >>>
# Launch fish for interactive sessions in environments that ignore the login shell
# (e.g. lxc-attach, Docker). Remove this block if you prefer bash as your interactive shell.
if [ -t 1 ] && command -v fish >/dev/null 2>&1; then
    exec fish
fi
# <<< dotfiles fish launcher <<<
FISH_LAUNCHER
    
    print_info "Fish launcher added to .bashrc"
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    print_header "Installation Summary"
    echo ""
    print_info "Package Manager: $PACKAGE_MANAGER"
    print_info "Selected components:"
    for component in "${SELECTED_COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary stow_dir is_cask <<< "$component"
        echo "  • $display_name"
    done
    
    echo ""
    
    # Show manual installation instructions if needed
    if [ ${#MANUAL_INSTALL_NEEDED[@]} -gt 0 ]; then
        print_warning "Manual installation required for:"
        for component in "${MANUAL_INSTALL_NEEDED[@]}"; do
            echo "  • $component"
        done
        echo ""
        show_manual_install_instructions
    fi
    
    echo ""
    if [ "$DRY_RUN" = true ]; then
        print_warning "DRY RUN MODE - No changes were made"
        echo "Run without --dry-run to perform actual installation"
    else
        print_info "Installation complete!"
        echo ""
        echo "Next steps:"
        echo "  1. Restart your terminal to load new configs"
        echo "  2. Open Neovim and run :Lazy sync (if installed)"
        echo "  3. Check that everything works as expected"
    fi
}

# ============================================================================
# Manual Installation Instructions
# ============================================================================

show_manual_install_instructions() {
    echo "Manual installation instructions:"
    echo ""
    
    for component in "${MANUAL_INSTALL_NEEDED[@]}"; do
        case $component in
            "Neovim")
                echo "📦 Neovim:"
                echo "  # Download latest from GitHub releases:"
                echo "  curl -fLo /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
                echo "  sudo tar -C /opt -xzf /tmp/nvim.tar.gz && sudo mv /opt/nvim-linux-x86_64 /opt/nvim"
                echo "  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim"
                echo ""
                ;;
            "Starship")
                echo "📦 Starship:"
                echo "  curl -sS https://starship.rs/install.sh | sh"
                echo ""
                ;;
            "Lazygit")
                echo "📦 Lazygit:"
                echo "  LAZYGIT_VERSION=\$(curl -s \"https://api.github.com/repos/jesseduffield/lazygit/releases/latest\" | grep -Po '\"tag_name\": \"v\K[^\"]*')"
                echo "  curl -Lo lazygit.tar.gz \"https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_\${LAZYGIT_VERSION}_Linux_x86_64.tar.gz\""
                echo "  tar xf lazygit.tar.gz lazygit"
                echo "  sudo install lazygit /usr/local/bin"
                echo ""
                ;;
            "Wezterm")
                echo "📦 Wezterm:"
                echo "  # Download from: https://wezfurlong.org/wezterm/install/linux.html"
                echo "  # Or use flatpak: flatpak install flathub org.wezfurlong.wezterm"
                echo ""
                ;;
            "VSCode")
                echo "📦 VSCode:"
                echo "  # Download from: https://code.visualstudio.com/download"
                echo "  # Or: sudo snap install code --classic"
                echo ""
                ;;
        esac
    done
}

# ============================================================================
# Main
# ============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Interactive dotfiles installer with automatic dependency management.

OPTIONS:
    --dry-run           Show what would be installed without making changes
    --all               Auto-select all components (skip interactive menu)
    --non-interactive   Run in non-interactive mode (implies --all)
    --unstow            Remove all stowed configurations
    -h, --help          Show this help message

EXAMPLES:
    $0                      Run interactive installation
    $0 --dry-run            Preview what would be installed
    $0 --all --dry-run      Preview installing all components
    $0 --non-interactive    Install everything without prompts
    $0 --unstow             Remove all symlinked configurations

NOTES:
    • Configs are symlinked as directories (e.g., ~/.config/nvim -> dotfiles/nvim/)
    • Fish shell dependencies (eza, bat, fzf, zoxide, etc.) are optional but recommended
    • Works with brew (macOS/Linux), apt-get, dnf, or pacman

EOF
}

unlink_all() {
    print_header "Unlinking all configurations"
    
    echo "This will remove all symlinked configurations."
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Unlink cancelled"
        exit 0
    fi
    
    local packages=("fish" "nvim" "tmux" "wezterm" "starship" "lazygit")
    
    for pkg in "${packages[@]}"; do
        local target="$HOME/.config/$pkg"
        if [ -L "$target" ]; then
            echo ""
            print_step "Unlinking $pkg..."
            rm "$target"
            print_info "✓ $pkg unlinked"
        fi
    done
    
    # Unlink vscode/cursor
    local OS=$(detect_os)
    case $OS in
        macos)
            for dir in "Code" "Cursor"; do
                local target="$HOME/Library/Application Support/$dir/User"
                if [ -d "$target" ]; then
                    for file in "$target"/*; do
                        if [ -L "$file" ]; then
                            rm "$file"
                        fi
                    done
                    print_info "✓ $dir configs unlinked"
                fi
            done
            ;;
        linux)
            for dir in "Code" "Cursor"; do
                local target="$HOME/.config/$dir/User"
                if [ -d "$target" ]; then
                    for file in "$target"/*; do
                        if [ -L "$file" ]; then
                            rm "$file"
                        fi
                    done
                    print_info "✓ $dir configs unlinked"
                fi
            done
            ;;
    esac
    
    echo ""
    print_info "Unlink complete!"
    echo "All symlinks have been removed."
}

main() {
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --dry-run)
                DRY_RUN=true
                ;;
            --all)
                AUTO_SELECT_ALL=true
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                AUTO_SELECT_ALL=true
                ;;
            --unstow)
                UNSTOW_MODE=true
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $arg"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Print banner
    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}Dotfiles Interactive Installer${NC}    ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════╝${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "Running in DRY RUN mode - no changes will be made"
    fi
    
    # Handle unstow mode
    if [ "$UNSTOW_MODE" = true ]; then
        unlink_all
        exit 0
    fi
    
    # Run installation steps
    detect_package_manager
    select_components
    check_and_install_components
    link_configs
    setup_fish_shell
    print_summary
}

main "$@"
