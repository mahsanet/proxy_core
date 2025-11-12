#!/bin/bash
clear

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Title of the script
echo -e "${BLUE}=== Building .so lib and header file for Android ARM64 and AMD64, and running ffigen ===${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$(dirname "$0")"
BUILD_DIR="$SCRIPT_DIR/.android_build"
ARM64_DIR="$BUILD_DIR/arm64"
AMD64_DIR="$BUILD_DIR/amd64"

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Change to the grpcserver command directory
change_directory() {
    echo -e "${CYAN}Changing directory to $SCRIPT_DIR/../src...${NC}"
    cd "$SCRIPT_DIR/../src" || handle_error "Failed to change directory to src."
}

# Check for environment variables NDK_HOME or ANDROID_NDK_HOME for macOS
set_ndk_path() {
  # Get OS type
  OS_NAME="$(uname -s)"

  # Map to NDK host tag
  case "$OS_NAME" in
      Linux*)     HOST_TAG=linux-x86_64;;
      Darwin*)    HOST_TAG=darwin-x86_64;;
      CYGWIN*|MINGW*) HOST_TAG=windows-x86_64;;
      *)          echo "Unsupported OS: $OS_NAME" && exit 1;;
  esac

  echo "Detected host tag: $HOST_TAG"
    if [ -n "$NDK_HOME" ]; then
        NDK_PATH="$NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/"
    elif [ -n "$ANDROID_NDK_HOME" ]; then
        NDK_PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/"
    else
        handle_error "Android NDK path not found. Please set either NDK_HOME or ANDROID_NDK_HOME environment variable.\nExample for macOS:\nexport NDK_HOME=/Users/[user_name]/Library/Android/sdk/ndk/27.0.12077973"
    fi

    # Check if the NDK path exists
    if [ ! -d "$NDK_PATH" ]; then
        handle_error "The NDK toolchain directory does not exist at: $NDK_PATH\nPlease ensure you have the Android NDK installed and the path is correct."
    fi
}

# Create build directories
create_build_directories() {
    mkdir -p "$ARM64_DIR" "$AMD64_DIR"
}

# Build the Go project for a specified architecture
build_go_project() {
    local arch=$1
    local goarch=$2
    local cc=$3
    local output_dir=$4

    echo -e "${YELLOW}Building the Go project for $arch...${NC}"
    GOARCH="$goarch" \
    GOOS=android \
    CGO_ENABLED=1 \
    CC="$cc" \
    go build -buildmode=c-shared -v -ldflags="-s -w" -trimpath -o "$output_dir/libproxy_core.so" cmd/main.go

    if [ $? -ne 0 ]; then
        handle_error "$arch build failed."
    fi

    echo -e "${GREEN}$arch build successful!${NC} Output saved to $output_dir/libproxy_core.so"
}

# Run ffigen
run_ffigen() {
    echo -e "${YELLOW}Running ffigen...${NC}"
    flutter pub run ffigen --config ffigen.yaml

    if [ $? -ne 0 ]; then
        handle_error "ffigen failed."
    fi

    echo -e "${GREEN}ffigen successful!${NC}"
}

# Main build function
build_android_libraries() {
    change_directory
    set_ndk_path
    create_build_directories

    # Build for ARM64
    build_go_project "ARM64" "arm64" "${NDK_PATH}aarch64-linux-android35-clang" "$ARM64_DIR"

    # Build for AMD64
    build_go_project "AMD64" "amd64" "${NDK_PATH}x86_64-linux-android35-clang" "$AMD64_DIR"

    # Run ffigen after successful builds

    # Uncomment the next line to run ffigen
    # Commented out to avoid running ffigen automatically in cache as it does not work in .pub-cache
    # run_ffigen

    echo -e "${GREEN}Successfully built Android libraries!${NC}"
}

# Call the main build function
build_android_libraries
