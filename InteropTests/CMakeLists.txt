cmake_minimum_required(VERSION 3.21.0)

project(InteropTests LANGUAGES C Swift)

if (NOT DEFINED SWIFT_WINRT_EXE)
    message(FATAL_ERROR "SWIFT_WINRT_EXE must be defined")
endif()
cmake_path(ABSOLUTE_PATH SWIFT_WINRT_EXE NORMALIZE OUTPUT_VARIABLE SWIFT_WINRT_EXE)

# Build WinRTComponent.winmd/dll
message(STATUS "Building WinRTComponent...")
cmake_path(CONVERT "${CMAKE_CURRENT_SOURCE_DIR}/WinRTComponent/Build.ps1" TO_NATIVE_PATH_LIST SCRIPT_PATH_ARG)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SCRIPT_PATH_ARG}")
cmake_path(CONVERT "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent" TO_NATIVE_PATH_LIST BINARY_DIR_BASE_ARG)
execute_process(
    COMMAND powershell.exe -File "${SCRIPT_PATH_ARG}"
        -BinaryDirBase "${BINARY_DIR_BASE_ARG}"
    COMMAND_ERROR_IS_FATAL ANY)
set(WINRTCOMPONENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent/bin/WinRTComponent")

# Generate Swift projection
message(STATUS "Generating Swift projection for WinRTComponent...")
cmake_path(CONVERT "${CMAKE_CURRENT_SOURCE_DIR}/GenerateProjection.ps1" TO_NATIVE_PATH_LIST SCRIPT_PATH_ARG)
cmake_path(CONVERT "${SWIFT_WINRT_EXE}" TO_NATIVE_PATH_LIST SWIFT_WINRT_EXE_ARG)
cmake_path(CONVERT "${WINRTCOMPONENT_BINARY_DIR}/WinRTComponent.winmd" TO_NATIVE_PATH_LIST WINMD_ARG)
cmake_path(CONVERT "${CMAKE_CURRENT_BINARY_DIR}/Generated/Sources" TO_NATIVE_PATH_LIST OUTPUT_DIR_ARG)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SCRIPT_PATH_ARG}")
execute_process(
    COMMAND powershell.exe -File "${SCRIPT_PATH_ARG}"
        -SwiftWinRT "${SWIFT_WINRT_EXE_ARG}"
        -WinMD "${WINMD_ARG}"
        -OutputDir "${OUTPUT_DIR_ARG}"
    COMMAND_ERROR_IS_FATAL ANY)

# Build the Swift projection
add_subdirectory(../Support ${CMAKE_CURRENT_BINARY_DIR}/Support)

# TODO(https://github.com/tristanlabelle/swift-winrt/issues/302): Fix linking issues
# add_subdirectory(
#     ${CMAKE_CURRENT_BINARY_DIR}/Generated/Sources
#     ${CMAKE_CURRENT_BINARY_DIR}/Generated/Build)