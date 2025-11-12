#!/bin/bash

# Default options
VERBOSE=false
SKIP_ADB=false
PACKAGE_NAME="com.mahsanet.proxy_core_example" # Default package name

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -v|--verbose) VERBOSE=true ;;
    --skip-adb) SKIP_ADB=true ;;
    -p|--package) PACKAGE_NAME="$2"; shift ;;
    -h|--help) 
      echo "Usage: ./presetup.sh [options]"
      echo "Options:"
      echo "  -v, --verbose     Enable verbose mode"
      echo "  --skip-adb        Skip ADB uninstall step" 
      echo "  -p, --package     Specify package name for ADB uninstall"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Print function for verbose mode
function print_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  fi
}

# Error handling function
function handle_error() {
  echo "Error: $1"
  exit 1
}

# Check if command exists
function check_command() {
  if ! command -v $1 &> /dev/null; then
    handle_error "$1 command not found. Please install it first."
  fi
}

# Remove .lock files
function remove_lock_files() {
  print_verbose "Removing .lock files..."
  find . -type f -name "*.lock" -delete || handle_error "Failed to remove lock files"
  print_verbose "✓ Lock files removed"
}

# Run Flutter clean
function flutter_clean() {
  check_command flutter
  
  # print_verbose "Running 'flutter clean'..."
  # flutter clean || handle_error "Flutter clean failed in root directory"
  # print_verbose "✓ Flutter clean completed in root directory"
  
  if [ -d "example" ]; then
    print_verbose "Running 'flutter clean' in example folder..."
    (cd example && flutter clean) || handle_error "Flutter clean failed in example directory"
    print_verbose "✓ Flutter clean completed in example directory"
  fi
}

# Remove build directories
function remove_build_dirs() {
  print_verbose "Removing build directories..."
  
  # Remove cxx and CMake related files
  rm -rf android/build/ android/.cxx android/CMakeFiles android/CMakeCache.txt android/cmake_install.cmake android/Makefile
  print_verbose "✓ Removed cxx and CMake related files"
  
  # Remove jniLibs content
     rm -rf android/src/main/jniLibs/*
     print_verbose "✓ Removed jniLibs content"
  
  # Remove Frameworks content
     rm -rf ios/Frameworks/libproxy_core.xcframework macos/Frameworks/libproxy_core.xcframework
     print_verbose "✓ Removed Frameworks content"
}

# Remove the app using adb
function remove_app_with_adb() {
  if [ "$SKIP_ADB" = true ]; then
    print_verbose "Skipping ADB uninstall step"
    return
  fi
  
  check_command adb
  
  print_verbose "Checking ADB devices..."
  local devices=$(adb devices | grep -v "List" | grep "device$")
  if [ -z "$devices" ]; then
    handle_error "No ADB devices found. Please connect a device first."
  fi
  
  print_verbose "Uninstalling package: $PACKAGE_NAME"
  if adb uninstall "$PACKAGE_NAME" &> /dev/null; then
    print_verbose "✓ App uninstalled successfully"
  else
    print_verbose "! App was not installed or failed to uninstall"
  fi
}

# Run all tasks
function run_all_tasks() {
  print_verbose "Starting presetup tasks..."
  
  # Create required directories if they don't exist
  mkdir -p android/src/main/jniLibs ios/Frameworks macos/Frameworks
  
  remove_lock_files
  flutter_clean
  remove_build_dirs
  remove_app_with_adb
  
  print_verbose "✓ All presetup tasks completed successfully"
  
  if [ "$VERBOSE" = false ]; then
    echo "Setup completed successfully"
  fi
}

# Execute main function
run_all_tasks