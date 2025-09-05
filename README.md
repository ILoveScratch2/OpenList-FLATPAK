# OpenList Flatpak Repository

This repository contains the Flatpak package configuration for OpenList, designed to automatically create Flatpak packages for Linux distributions. It monitors the main OpenList repository for new releases and automatically builds corresponding Flatpak packages.

## Repository Structure

```
├── .github/workflows/
│   └── build-flatpak.yml       # GitHub Actions workflow
├── icons/                      # Application icons in various sizes
│   ├── 16x16.png              # Icon files copied from Logo repository
│   ├── 32x32.png
│   ├── 48x48.png
│   └── ...
│   └── logo.svg               # SVG icon
├── org.oplist.openlist.yml     # Flatpak manifest template
├── org.oplist.openlist.desktop # Desktop entry file
├── org.oplist.openlist.metainfo.xml # AppStream metadata
├── openlist-wrapper.sh        # Wrapper script for proper data handling
├── build.sh                   # Local build script
└── README.md                  # This file
```


## Local Building

### Prerequisites

- `flatpak` and `flatpak-builder`
- `jq` (for JSON parsing)
- `wget`, `tar`, `sha256sum`
- Flatpak runtime and SDK:
  ```bash
  flatpak install flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08
  ```

### Build Latest Version

```bash
chmod +x build.sh
./build.sh
```

### Build Specific Version

```bash
./build.sh --version 1.2.3 --arch x86_64
```

### Build Script Options

- `-v, --version VERSION`: Set package version (default: fetch latest from GitHub)
- `-a, --arch ARCH`: Set architecture (x86_64 or aarch64, default: x86_64)
- `-d, --debug`: Enable debug output
- `-h, --help`: Show help message

### Manual Flatpak Build

```bash
# Generate manifest for specific version
./build.sh --version 1.2.3 --arch x86_64

# Build with flatpak-builder
flatpak-builder --repo=repo --force-clean build-dir org.oplist.openlist-1.2.3-x86_64.yml

# Create bundle
flatpak build-bundle repo org.oplist.openlist-1.2.3-x86_64.flatpak org.oplist.openlist

# Install locally
flatpak install --user --bundle org.oplist.openlist-1.2.3-x86_64.flatpak -y
```

## GitHub Actions Configuration

### Automatic Triggers

- **Schedule**: Daily at 2 AM UTC
- **Manual**: Via workflow dispatch

### Required Secrets (for GPG signing)

Configure these secrets in your GitHub repository settings:

- `GPG_PRIVATE_KEY`: Your GPG private key for signing packages
- `GPG_PASSPHRASE`: Passphrase for your GPG key  
- `GPG_KEY_ID`: Your GPG key ID

## Installation

### One-line Installation (Recommended)

```bash
curl -fsSL https://github.com/OpenListTeam/OpenList-FLATPAK/releases/latest/download/install-flatpak.sh | bash
```

### Manual Installation

#### Prerequisites
```bash
# Install Flatpak (if not already installed)
# On Ubuntu/Debian
sudo apt install flatpak

# On Fedora  
sudo dnf install flatpak

# On Arch Linux
sudo pacman -S flatpak

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

#### Install from GitHub Releases

```bash
# Download latest release (x86_64)
wget https://github.com/OpenListTeam/OpenList-FLATPAK/releases/latest/download/org.oplist.openlist-VERSION-x86_64.flatpak

# Install
flatpak install --user --bundle org.oplist.openlist-VERSION-x86_64.flatpak -y
```

#### Install from Local Build

```bash
# After building locally
flatpak install --user --bundle org.oplist.openlist-VERSION-ARCH.flatpak -y
```

## Usage

### Running OpenList

```bash
# Start OpenList server (typical usage)
flatpak run org.oplist.openlist server

# Show version
flatpak run org.oplist.openlist version

# Show help
flatpak run org.oplist.openlist --help

# Run with specific arguments
flatpak run org.oplist.openlist server --port 5244
```

### Management

```bash
# Update to latest version
flatpak update org.oplist.openlist

# Show application information
flatpak info org.oplist.openlist

# Uninstall
flatpak uninstall org.oplist.openlist

# List all installed Flatpak applications
flatpak list --app
```


## Troubleshooting

### Common Issues

#### Flatpak Not Found
```bash
# Install Flatpak first
sudo apt install flatpak        # Ubuntu/Debian
sudo dnf install flatpak        # Fedora
sudo pacman -S flatpak          # Arch Linux
```

#### Runtime Missing
```bash
# Install required runtime
flatpak install flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08
```

#### Permission Issues
```bash
# Reset application data
rm -rf ~/.local/share/openlist/*
rm -rf ~/.config/openlist/*

# Or run with verbose output to debug
flatpak run --verbose org.oplist.openlist server
```

#### Application Won't Start
```bash
# Check logs
journalctl --user -f _SYSTEMD_USER_UNIT=org.oplist.openlist.service

# Run in shell for debugging
flatpak run --command=sh org.oplist.openlist
```

### Complete Uninstallation

```bash
# Stop any running instances
pkill -f 'flatpak.*org.oplist.openlist' || true

# Uninstall the application
flatpak uninstall org.oplist.openlist -y

# Remove all data (optional)
rm -rf ~/.local/share/openlist
rm -rf ~/.config/openlist  
rm -rf ~/.var/app/org.oplist.openlist
```

## Development

### Testing Locally

1. Clone this repository
2. Install required Flatpak runtimes
3. Run the build script: `./build.sh`
4. Install the generated bundle: `flatpak install --user --bundle *.flatpak -y`
5. Test the application: `flatpak run org.oplist.openlist --help`


## Binary Sources

The Flatpak packages automatically download the appropriate binary from:
- x86_64: `https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-linux-amd64.tar.gz`  
- aarch64: `https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-linux-arm64.tar.gz`

## License

This packaging configuration follows the same license as the main OpenList project (AGPL-3.0-or-later).
