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

# Component definitions
# Format: "display_name:brew_package:apt_package:binary_name:stow_dir:is_cask"
# Note: "MANUAL" means requires special installation steps
declare -a COMPONENTS=(
    "Fish Shell:fish:fish:fish:fish:0"
    "Neovim:neovim:neovim:nvim:nvim:0"
    "Tmux:tmux:tmux:tmux:tmux:0"
    "Wezterm:wezterm:MANUAL:wezterm:wezterm:1"
    "Starship:starship:MANUAL:starship:starship:0"
    "Lazygit:jesseduffield/lazygit/lazygit:MANUAL:lazygit:lazygit:0"
    "VSCode:visual-studio-code:MANUAL:code:vscode:1"
    "Cursor:cursor:N/A:cursor:vscode:1"
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
        SELECTED_COMPONENTS=("${COMPONENTS[@]}")
        print_info "Auto-selected all components (${#SELECTED_COMPONENTS[@]} total)"
        return
    fi
    
    # Check if fzf is available for better UX
    if command -v fzf &> /dev/null; then
        select_components_fzf
    else
        select_components_simple
    fi
}

select_components_fzf() {
    echo "Use TAB to select/deselect, ENTER to confirm"
    echo ""
    
    # Create options list
    local options=()
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary stow_dir is_cask <<< "$component"
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
            IFS=':' read -r comp_display brew_pkg apt_pkg binary stow_dir is_cask <<< "$component"
            if [ "$comp_display" = "$display_name" ]; then
                SELECTED_COMPONENTS+=("$component")
                break
            fi
        done
    done <<< "$selected"
}

select_components_simple() {
    echo "Select components (y/n):"
    echo ""
    
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary stow_dir is_cask <<< "$component"
        
        read -p "  Install $display_name? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SELECTED_COMPONENTS+=("$component")
        fi
    done
    
    if [ ${#SELECTED_COMPONENTS[@]} -eq 0 ]; then
        print_warning "No components selected. Exiting."
        exit 0
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

check_and_install_components() {
    print_header "Checking and installing components"
    
    for component in "${SELECTED_COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary stow_dir is_cask <<< "$component"
        
        echo ""
        print_step "Processing: $display_name"
        
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
            print_warning "$display_name requires manual installation via $PACKAGE_MANAGER"
            MANUAL_INSTALL_NEEDED+=("$display_name")
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
# Stow Configuration Files
# ============================================================================

stow_configs() {
    print_header "Stowing configuration files"
    
    # Check if stow is installed
    if ! command -v stow &> /dev/null; then
        print_step "Installing GNU Stow..."
        if [ "$DRY_RUN" = false ]; then
            install_package "stow" "0"
        else
            print_warning "[DRY RUN] Would install: stow (via $PACKAGE_MANAGER)"
        fi
    fi
    
    local OS=$(detect_os)
    
    for component in "${SELECTED_COMPONENTS[@]}"; do
        IFS=':' read -r display_name brew_pkg apt_pkg binary stow_dir is_cask <<< "$component"
        
        echo ""
        print_step "Stowing $display_name configs"
        
        # Handle VSCode/Cursor specially (platform-specific paths)
        if [ "$stow_dir" = "vscode" ]; then
            stow_vscode_configs "$display_name" "$OS"
        else
            # Regular stow to ~/.config
            if [ -d "$stow_dir" ]; then
                if [ "$DRY_RUN" = true ]; then
                    print_warning "[DRY RUN] Would stow: $stow_dir → ~/.config/"
                else
                    stow "$stow_dir" 2>/dev/null && print_info "✓ $display_name configs stowed" || print_warning "Config already exists, skipping"
                fi
            else
                print_warning "No config directory found for $display_name (expected: $stow_dir/)"
            fi
        fi
    done
}

stow_vscode_configs() {
    local app_name=$1
    local os=$2
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
    
    if [ -d "$target_dir" ]; then
        if [ "$DRY_RUN" = true ]; then
            print_warning "[DRY RUN] Would stow: vscode → $target_dir"
        else
            stow -t "$target_dir" vscode 2>/dev/null && print_info "✓ $app_name configs stowed" || print_warning "Config already exists, skipping"
        fi
    else
        print_warning "$app_name directory not found at: $target_dir"
        print_warning "Install $app_name first, then re-run this script"
    fi
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
        return
    fi
    
    echo ""
    
    if [ "$NON_INTERACTIVE" = true ]; then
        print_info "Non-interactive mode: Skipping default shell change"
        return
    fi
    
    echo "Fish is installed but not your default shell."
    read -p "Would you like to set Fish as your default shell? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$DRY_RUN" = true ]; then
            print_warning "[DRY RUN] Would set fish as default shell"
            return
        fi
        
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
    -h, --help          Show this help message

EXAMPLES:
    $0                      Run interactive installation
    $0 --dry-run            Preview what would be installed
    $0 --all --dry-run      Preview installing all components
    $0 --non-interactive    Install everything without prompts

EOF
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
    
    # Run installation steps
    detect_package_manager
    select_components
    check_and_install_components
    stow_configs
    setup_fish_shell
    print_summary
}

main "$@"
