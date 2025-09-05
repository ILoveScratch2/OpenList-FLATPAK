#!/bin/bash

set -e

# Default values
VERSION=""
ARCH="x86_64"
USE_LATEST=true
DEBUG=false


while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            USE_LATEST=false
            shift 2
            ;;
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -d|--debug)
            DEBUG=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --version VERSION    Set package version (default: fetch latest from GitHub)"
            echo "  -a, --arch ARCH         Set architecture (x86_64 or aarch64, default: x86_64)"
            echo "  -d, --debug             Enable debug output"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done


if [ "$DEBUG" = "true" ]; then
    set -x
fi

# Validate architecture
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
    echo "Error: Architecture must be either 'x86_64' or 'aarch64'"
    exit 1
fi


case $ARCH in
    "x86_64")
        OPENLIST_ARCH="amd64"
        ;;
    "aarch64")
        OPENLIST_ARCH="arm64"
        ;;
esac

echo "=== OpenList Flatpak Builder ==="
echo "Debug mode: $DEBUG"
echo "Architecture: $ARCH (OpenList: $OPENLIST_ARCH)"

# Get latest version from GitHub if not specified
if [[ "$USE_LATEST" == "true" ]]; then
    echo "Fetching latest OpenList version from GitHub..."
    
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required to fetch version from GitHub API"
        echo "Please install jq or specify version manually with -v option"
        exit 1
    fi
    echo "Calling GitHub API..."
    RELEASE_INFO=$(curl -s "https://api.github.com/repos/OpenListTeam/OpenList/releases/latest")
    
    if [ "$DEBUG" = "true" ]; then
        echo "API Response:"
        echo "$RELEASE_INFO" | jq '.' || echo "Failed to parse JSON"
    fi
    
    TAG_NAME=$(echo "$RELEASE_INFO" | jq -r '.tag_name // empty')
    
    if [ -z "$TAG_NAME" ] || [ "$TAG_NAME" = "null" ] || [ "$TAG_NAME" = "empty" ]; then
        echo "Error: Failed to get tag_name from API response"
        echo "Using fallback version"
        TAG_NAME="v1.0.0"
    fi
    
    VERSION=${TAG_NAME#v}  # Remove 'v' prefix if present
    
    if [[ "$VERSION" == "null" || -z "$VERSION" ]]; then
        echo "Error: Failed to fetch latest version from GitHub"
        exit 1
    fi
    
    echo "Latest version found: $VERSION (tag: $TAG_NAME)"
else
    TAG_NAME="v$VERSION"
fi


CLEAN_VERSION=$(echo "$VERSION" | sed 's/^v//')

echo "=== Version Information ==="
echo "Original TAG_NAME: $TAG_NAME"
echo "Extracted VERSION: $VERSION"
echo "Clean VERSION: $CLEAN_VERSION"

# Validate version format
if [[ ! "$CLEAN_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    echo "Error: Version format is invalid: $CLEAN_VERSION"
    echo "Expected format: x.y.z (e.g., 1.0.0)"
    exit 1
fi

echo "Building OpenList Flatpak..."
echo "Version: $CLEAN_VERSION"
echo "Architecture: $ARCH"


echo "=== Checking for required tools ==="
MISSING_TOOLS=()

for tool in wget tar sha256sum; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Error: Missing required tools: ${MISSING_TOOLS[*]}"
    echo "Please install them"
    exit 1
fi


echo "=== Downloading OpenList binary for $OPENLIST_ARCH ==="
DOWNLOAD_URL="https://github.com/OpenListTeam/OpenList/releases/download/$TAG_NAME/openlist-linux-$OPENLIST_ARCH.tar.gz"
echo "Download URL: $DOWNLOAD_URL"

if ! wget -O "openlist-linux-$OPENLIST_ARCH.tar.gz" "$DOWNLOAD_URL"; then
    echo "Error: Failed to download binary for $OPENLIST_ARCH"
    exit 1
fi


echo "=== Calculating SHA256 hash ==="
BINARY_SHA256=$(sha256sum "openlist-linux-$OPENLIST_ARCH.tar.gz" | awk '{print $1}')
echo "SHA256: $BINARY_SHA256"

echo "=== Updating Flatpak manifest ==="
sed -e "s|RELEASE_TAG|$TAG_NAME|g" \
    -e "s|BINARY_SHA256|$BINARY_SHA256|g" \
    -e "s|openlist-linux-amd64.tar.gz|openlist-linux-$OPENLIST_ARCH.tar.gz|g" \
    -e "s|openlist-linux-amd64|openlist-linux-$OPENLIST_ARCH|g" \
    org.oplist.openlist.yml > "org.oplist.openlist-$CLEAN_VERSION-$ARCH.yml"

# Update MetaInfo with version and date
CURRENT_DATE=$(date +%Y-%m-%d)
sed -e "s|PLACEHOLDER_VERSION|$CLEAN_VERSION|g" \
    -e "s|PLACEHOLDER_DATE|$CURRENT_DATE|g" \
    org.oplist.openlist.metainfo.xml > "org.oplist.openlist-$CLEAN_VERSION.metainfo.xml"

# Cleanup
rm -f "openlist-linux-$OPENLIST_ARCH.tar.gz"

echo "=== Build completed successfully! ==="
echo "Generated manifest: org.oplist.openlist-$CLEAN_VERSION-$ARCH.yml"
echo "Generated MetaInfo: org.oplist.openlist-$CLEAN_VERSION.metainfo.xml"
echo ""
echo "To build the Flatpak:"
if [ "$ARCH" = "aarch64" ]; then
    echo "# For ARM64/aarch64 (requires cross-compilation runtime):"
    echo "flatpak install flathub org.freedesktop.Platform/aarch64/23.08 org.freedesktop.Sdk/aarch64/23.08"
    echo "flatpak-builder --arch=aarch64 --repo=repo --force-clean build-dir org.oplist.openlist-$CLEAN_VERSION-$ARCH.yml"
    echo "flatpak build-bundle --arch=aarch64 repo org.oplist.openlist-$CLEAN_VERSION-$ARCH.flatpak org.oplist.openlist"
else
    echo "# For x86_64:"
    echo "flatpak-builder --repo=repo --force-clean build-dir org.oplist.openlist-$CLEAN_VERSION-$ARCH.yml"
    echo "flatpak build-bundle repo org.oplist.openlist-$CLEAN_VERSION-$ARCH.flatpak org.oplist.openlist"
fi
echo ""
echo "To install locally:"
echo "flatpak --user install --bundle org.oplist.openlist-$CLEAN_VERSION-$ARCH.flatpak -y"
