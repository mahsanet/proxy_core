@echo off
setlocal enabledelayedexpansion

:: Title of the script
echo ========================================================================
echo Building libproxy_core.dll using x86_64-w64-mingw32-gcc...
echo ========================================================================

:: Variables
set LIB_NAME=libproxy_core.dll
set ZIP_NAME=libproxy_core.zip
set CMD_DIR=..\src
set OUTPUT_DIR=%~dp0

:: Check if MinGW/MSYS is installed
where x86_64-w64-mingw32-gcc >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: x86_64-w64-mingw32-gcc not found. Please install MinGW/MSYS.
    exit /b 1
)
echo MinGW found!

:: Change to the main directory (src/)
cd /d "%~dp0%CMD_DIR%" || (
    echo Error: Failed to change directory to %CMD_DIR%.
    exit /b 1
)

:: Set environment variables for Go build
set CGO_ENABLED=1
set GOARCH=amd64
set GOOS=windows
set CC=x86_64-w64-mingw32-gcc

:: Run go build for Windows
echo Building %LIB_NAME%...
go build -ldflags="-s -w" -v -buildmode=c-shared -o "%OUTPUT_DIR%/%LIB_NAME%" cmd/main.go || (
    echo Error: Build failed!
    exit /b 1
)

:: Zip the DLL using PowerShell's Compress-Archive
echo Zipping %LIB_NAME% into %ZIP_NAME%...
powershell -command "Compress-Archive -Force -Path '%OUTPUT_DIR%%LIB_NAME%' -DestinationPath '%OUTPUT_DIR%%ZIP_NAME%'" || (
    echo Error: Failed to zip %LIB_NAME%.
    exit /b 1
)

:: Remove the DLL after zipping
echo Cleaning up: removing %LIB_NAME%...
del "%OUTPUT_DIR%/%LIB_NAME%" || (
    echo Error: Failed to remove %LIB_NAME%.
    exit /b 1
)

:: FFIGEN process to generate Dart FFI bindings
echo Running ffigen to generate Dart FFI bindings...
cd /d "%OUTPUT_DIR%../" || (
    echo "Failed to change directory to %OUTPUT_DIR%"
)

dart run ffigen --config ffigen.yaml || (
    echo "ffigen failed!"
)

:: Completion message
echo ========================================================================
echo Build and zipping of %LIB_NAME% completed successfully!
echo ========================================================================
