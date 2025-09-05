#!/bin/bash
# OpenList Flatpak wrapper script

set -e

# Flatpak application directories
FLATPAK_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/app/org.oplist.openlist"
OPENLIST_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/openlist"
OPENLIST_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/openlist"

# Create necessary directories
mkdir -p "$OPENLIST_DATA_DIR"
mkdir -p "$OPENLIST_CONFIG_DIR"

# Set environment variables for OpenList
export OPENLIST_DATA_DIR="$OPENLIST_DATA_DIR"
export OPENLIST_CONFIG_DIR="$OPENLIST_CONFIG_DIR"

# Change to data directory for consistent behavior
cd "$OPENLIST_DATA_DIR"

# Run the actual OpenList binary
exec "/app/bin/openlist-binary" "$@"
