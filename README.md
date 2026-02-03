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

```bash
# 1. Install Homebrew (required)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone the repository
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# 3. Run the interactive setup
./setup.sh
```

The script will:
1. ✅ Check that Homebrew is installed
2. 🎯 Let you select which components to install (Fish, Neovim, Tmux, etc.)
3. 📦 Auto-install missing tools via Homebrew
4. 🔗 Stow configuration files to the correct locations
5. 🐚 Optionally set Fish as your default shell

## 📋 Available Components

- **Fish Shell** - Modern shell with great defaults
- **Neovim** - Hyperextensible Vim-based text editor
- **Tmux** - Terminal multiplexer
- **Wezterm** - GPU-accelerated terminal emulator
- **Starship** - Cross-shell prompt
- **Lazygit** - Simple terminal UI for git
- **VSCode** - Visual Studio Code editor
- **Cursor** - AI-first code editor

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

### Configuration Stowing

- **Common configs**: Stowed to `~/.config/` (fish, nvim, tmux, etc.)
- **VSCode/Cursor**: Platform-aware stowing
  - macOS: `~/Library/Application Support/Code|Cursor/User`
  - Linux: `~/.config/Code|Cursor/User`

### Dependency Management

The script checks if each selected tool is installed:
- ✅ Already installed → Skip to stowing configs
- ❌ Not installed → Install via `brew install <package>`

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

- **Homebrew** (required) - [Install here](https://brew.sh)
- **fzf** (optional) - Better interactive selection UX

## 📝 Help

```bash
./setup.sh --help
```

## 🙏 References

- [omerxx/dotfiles](https://github.com/omerxx/dotfiles) - Inspiration
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)

