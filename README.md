# Dotfiles

Cross-platform dotfiles managed with GNU Stow, supporting macOS and Linux with automatic dependency installation.

## ✨ Features

- 🎯 **Interactive component selection** - Choose exactly what you want to install
- 📦 **Automatic dependency installation** - Uses Homebrew to install missing tools
- 🖥️ **Cross-platform** - Works on macOS and Linux
- 🔍 **Dry-run mode** - Preview changes before applying
- 🐚 **Smart shell setup** - Optionally set Fish as default shell
- ⚡ **Fast and friendly** - Uses fzf for better UX when available

## 🚀 Quick Start

### macOS
```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone and run
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./setup.sh
```

### Linux (Debian/Ubuntu)
```bash
# No prerequisites needed! The script uses apt-get automatically

# Clone and run
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The script will:
1. ✅ Detect your package manager (brew/apt-get/dnf/pacman)
2. 🎯 Let you select which components to install (Fish, Neovim, Tmux, etc.)
3. 📦 Auto-install missing tools via your package manager
4. 🔗 Stow configuration files to the correct locations
5. 🐚 Optionally set Fish as your default shell

## 📋 Available Components

- **Fish Shell** - Modern shell with great defaults
- **Neovim** - Hyperextensible Vim-based text editor
- **Tmux** - Terminal multiplexer
- **Wezterm** - GPU-accelerated terminal emulator
- **Starship** - Cross-shell prompt
- **Lazygit** - Simple terminal UI for git
- **Worktrunk** - Git worktree management with Fish and Bitbucket PR switching
- **VSCode** - Visual Studio Code editor
- **Cursor** - AI-first code editor

### Worktrunk

Selecting Worktrunk links the tracked configuration to `~/.config/worktrunk/`.

- `wt create <branch>` fetches `origin`, creates the worktree from `origin/main`, and enters it.
- `wt switch <Bitbucket PR URL>` resolves the PR source branch with `atlas prflow branch` before switching.
- `wt switch` keeps Worktrunk's native picker, including `Alt-x` to remove the selected worktree.

## 🎮 Usage

### Interactive Mode (Default)
```bash
./setup.sh
```
Uses `fzf` for multi-select menu if available, otherwise simple y/n prompts.

### Dry Run Mode
Preview what would be installed without making changes:
```bash
./setup.sh --dry-run
```

### Auto-Select All Components
Skip the interactive menu and install everything:
```bash
./setup.sh --all
```

### Non-Interactive Mode
Perfect for scripts/automation:
```bash
./setup.sh --non-interactive
```

### Combining Options
```bash
# Preview installing everything
./setup.sh --all --dry-run

# Install everything without prompts
./setup.sh --non-interactive
```

## 📖 How It Works

### Package Manager Detection

The script automatically detects and uses the best package manager for your system:
- **Linux**: Prefers system package managers (apt-get, dnf, pacman)
- **macOS**: Uses Homebrew
- **Works as root**: On Linux, uses apt-get/dnf/pacman which work with root
- **Works as regular user**: Uses Homebrew or system packages with sudo

### Configuration Stowing

- **Common configs**: Stowed to `~/.config/` (fish, nvim, tmux, etc.)
- **VSCode/Cursor**: Platform-aware stowing
  - macOS: `~/Library/Application Support/Code|Cursor/User`
  - Linux: `~/.config/Code|Cursor/User`

### Dependency Management

The script checks if each selected tool is installed:
- ✅ Already installed → Skip to stowing configs
- ❌ Not installed → Install via detected package manager
- ⚠️ Manual install needed → Shows installation instructions for tools not in package manager

## 🛠️ Manual Installation

If you prefer manual control:

```bash
# Install GNU Stow
brew install stow

# Stow individual configs
stow fish
stow nvim
stow tmux

# Or stow everything (excluding vscode)
stow --ignore=vscode .

# VSCode/Cursor configs (macOS)
stow -t ~/Library/Application\ Support/Code/User vscode

# VSCode/Cursor configs (Linux)
stow -t ~/.config/Code/User vscode
```

## 🔧 Requirements

### macOS
- **Homebrew** (required) - [Install here](https://brew.sh)
- **fzf** (optional) - Better interactive selection UX

### Linux
- **apt-get, dnf, or pacman** (usually pre-installed)
- **fzf** (optional) - Better interactive selection UX
- **Or Homebrew** - Works on Linux too!

## 📝 Help

```bash
./setup.sh --help
```

## 🙏 References

- [omerxx/dotfiles](https://github.com/omerxx/dotfiles) - Inspiration
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
