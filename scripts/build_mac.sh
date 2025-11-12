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
echo -e "${BLUE}=== Building and zipping libproxy_core.xcframework for macOS ===${NC}"

# Set variables
STATIC_LIB_NAME="libproxy_core.a"
XCFRAMEWORK_NAME="libproxy_core.xcframework"
ZIP_NAME="libproxy_core.xcframework.zip"
CMD_DIR="../src/"
SCRIPT_DIR="$(pwd)"  # Current directory where the script is located

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Change to the grpcserver command directory
change_directory() {
    echo -e "${CYAN}Changing directory to $CMD_DIR...${NC}"
    cd "$CMD_DIR" || handle_error "Failed to change directory to $CMD_DIR."
}

# Set up environment for building macOS binaries
setup_go_env() {
    echo -e "${CYAN}Setting up environment for macOS build...${NC}"
    export CGO_ENABLED=1
    export GOARCH=arm64
    export GOOS=darwin
}

# Build for macOS
build_macos() {
    echo -e "${YELLOW}Building libproxy_core for macOS...${NC}"
    go build -ldflags="-s -w" -v -buildmode=c-archive -o "$SCRIPT_DIR/$STATIC_LIB_NAME" cmd/main.go

    [ $? -ne 0 ] && handle_error "Build for macOS failed."
}

# Create an XCFramework from the built macOS binary
create_xcframework() {
    echo -e "${CYAN}Creating XCFramework...${NC}"
    xcodebuild -create-xcframework \
        -library "$SCRIPT_DIR/$STATIC_LIB_NAME" \
        -output "$SCRIPT_DIR/$XCFRAMEWORK_NAME" || handle_error "Failed to create XCFramework."
}

# Zip the XCFramework
zip_xcframework() {
    echo -e "${CYAN}Zipping $XCFRAMEWORK_NAME into $ZIP_NAME...${NC}"

    # Temporarily change the directory to avoid full path inclusion in the zip
    (
        cd "$SCRIPT_DIR" || handle_error "Failed to change directory to $SCRIPT_DIR."
        zip -r "$ZIP_NAME" "$XCFRAMEWORK_NAME"
    )

    [ $? -ne 0 ] && handle_error "Failed to zip $XCFRAMEWORK_NAME."
}

# Clean up created files except the zip
cleanup() {
    echo -e "${YELLOW}Cleaning up: removing $XCFRAMEWORK_NAME and intermediary files...${NC}"
    rm -rf "$SCRIPT_DIR/$XCFRAMEWORK_NAME" "$SCRIPT_DIR/$STATIC_LIB_NAME"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to remove files.${NC}"
    else
        echo -e "${GREEN}Cleanup successful.${NC}"
    fi
}

# Main build function
build_xcframework() {
    change_directory
    setup_go_env

    # Build the macOS version of the library
    build_macos

    # Create the XCFramework
    create_xcframework

    # Zip the generated XCFramework
    zip_xcframework

    # Cleanup the created files, leaving only the zip
    cleanup

    echo -e "${GREEN}Successfully built and zipped $ZIP_NAME beside the script!${NC}"
}

# Call the main build function
build_xcframework
