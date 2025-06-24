#!/usr/bin/env bash

# Stow all packages (except vscode) to `.config` directory
echo "- Stowing .config files..."
stow --ignore=vscode .

# Stow `vscode` to Cursor and VSCode directories
echo -e "- Stowing vscode config files..."
stow -t ~/Library/Application\ Support/Code/User vscode

echo -e "- Stowing Cursor config files..."
stow -t ~/Library/Application\ Support/Cursor/User vscode
stow -t /Users/hosman/CursorData/HadyPersonal/User vscode
