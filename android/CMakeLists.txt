cmake_minimum_required(VERSION 3.10)

# Set the root directory where the build script is located
set(ProxyBuildRoot "${CMAKE_CURRENT_SOURCE_DIR}/../scripts")

# Set the destination directory for the organized .so files (jniLibs)
set(LibRoot "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs")

# Ensure the jniLibs subdirectories exist
file(MAKE_DIRECTORY ${LibRoot}/arm64-v8a)
file(MAKE_DIRECTORY ${LibRoot}/armeabi-v7a)
file(MAKE_DIRECTORY ${LibRoot}/x86)
file(MAKE_DIRECTORY ${LibRoot}/x86_64)

# Execute the build script
execute_process(
    COMMAND bash ${ProxyBuildRoot}/build_android.sh
    RESULT_VARIABLE build_result
)

if(NOT build_result EQUAL 0)
    message(FATAL_ERROR "Failed to build Android libraries. Please check the build script output for details.")
endif()

# Set the paths for the generated .so files
set(ARM64_SO_FILE "${ProxyBuildRoot}/.android_build/arm64/libproxy_core.so")
set(AMD64_SO_FILE "${ProxyBuildRoot}/.android_build/amd64/libproxy_core.so")

# Copy the ARM64 .so file to both arm64-v8a and armeabi-v7a folders in jniLibs
if(EXISTS ${ARM64_SO_FILE})
    file(COPY ${ARM64_SO_FILE} DESTINATION ${LibRoot}/arm64-v8a)
    file(COPY ${ARM64_SO_FILE} DESTINATION ${LibRoot}/armeabi-v7a)
    message(STATUS "Copied ${ARM64_SO_FILE} to ${LibRoot}/arm64-v8a and ${LibRoot}/armeabi-v7a")
else()
    message(FATAL_ERROR "ARM64 .so file not found after build: ${ARM64_SO_FILE}")
endif()

# Copy the AMD64 .so file to both x86 and x86_64 folders in jniLibs
if(EXISTS ${AMD64_SO_FILE})
    file(COPY ${AMD64_SO_FILE} DESTINATION ${LibRoot}/x86)
    file(COPY ${AMD64_SO_FILE} DESTINATION ${LibRoot}/x86_64)
    message(STATUS "Copied ${AMD64_SO_FILE} to ${LibRoot}/x86 and ${LibRoot}/x86_64")
else()
    message(FATAL_ERROR "AMD64 .so file not found after build: ${AMD64_SO_FILE}")
endif()

# Optional: Print a message to confirm the copy operation
message(STATUS "JNI libraries copied to the respective folders in ${LibRoot}")