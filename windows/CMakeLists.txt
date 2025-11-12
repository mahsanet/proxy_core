cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "proxy_core")
project(${PROJECT_NAME} LANGUAGES CXX)

# Path to your ZIP file.
set(PROXY_CORE_ZIP "${CMAKE_CURRENT_SOURCE_DIR}/libproxy_core.zip")

# Path to the unzipped DLL file.
set(PROXY_CORE_DLL "${CMAKE_CURRENT_SOURCE_DIR}/libproxy_core.dll")

# Ensure the ZIP file exists before proceeding.
if(NOT EXISTS ${PROXY_CORE_ZIP})
    message(FATAL_ERROR "ZIP file libproxy_core.zip not found at ${CMAKE_CURRENT_SOURCE_DIR}")
endif()

# Unzip the ZIP file regardless of the DLL's existence.
message(STATUS "Unzipping libproxy_core.zip...")
execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xvf "${PROXY_CORE_ZIP}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        RESULT_VARIABLE UNZIP_RESULT
)
if(NOT UNZIP_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to unzip libproxy_core.zip")
endif()

# Handle different build configurations (Debug, Release)
if(CMAKE_BUILD_TYPE STREQUAL "debug")
    set(FLUTTER_BINARY_DIR "${CMAKE_BINARY_DIR}/runner/Debug")
elseif(CMAKE_BUILD_TYPE STREQUAL "release")
    set(FLUTTER_BINARY_DIR "${CMAKE_BINARY_DIR}/runner/Release")
else()
    # We assume that it's building in debug mode by default.
    set(FLUTTER_BINARY_DIR "${CMAKE_BINARY_DIR}/runner/Debug")
endif()

# Ensure that the output directory exists.
file(MAKE_DIRECTORY ${FLUTTER_BINARY_DIR})

# Dummy target to allow the custom command to attach
add_custom_target(copy_proxy_core_dll ALL
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${PROXY_CORE_DLL}" "${FLUTTER_BINARY_DIR}/libproxy_core.dll"
        COMMENT "Copying libproxy_core.dll to the build output directory: ${FLUTTER_BINARY_DIR}"
)
