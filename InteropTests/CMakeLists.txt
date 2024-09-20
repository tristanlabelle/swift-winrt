cmake_minimum_required(VERSION 3.21.0)

if(NOT DEFINED CMAKE_PROJECT_NAME)
    project(InteropTests LANGUAGES C Swift)
endif()

if (NOT DEFINED SWIFT_WINRT_EXE)
    message(FATAL_ERROR "SWIFT_WINRT_EXE must be defined")
endif()
cmake_path(ABSOLUTE_PATH SWIFT_WINRT_EXE NORMALIZE OUTPUT_VARIABLE SWIFT_WINRT_EXE)

# Generating projection sources will depend on WinRTComponent.winmd, so build it now
message(STATUS "Configuring WinRTComponent subproject...")
execute_process(
    COMMAND ${CMAKE_COMMAND}
        -S "${CMAKE_CURRENT_SOURCE_DIR}/WinRTComponent"
        -B "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent"
        -G "${CMAKE_GENERATOR}"
        -D "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
        -D CMAKE_CXX_COMPILER=cl.exe
        -D "CMAKE_CXX_FLAGS=/std:c++latest /W4 /EHsc"
    COMMAND_ERROR_IS_FATAL ANY)

message(STATUS "Building WinRTComponent subproject...")
execute_process(
    COMMAND ${CMAKE_COMMAND}
        --build "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent"
    COMMAND_ERROR_IS_FATAL ANY)
set(WINRTCOMPONENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent")

# Generate Swift projection
message(STATUS "Generating Swift projection for WinRTComponent...")
cmake_path(CONVERT "${CMAKE_CURRENT_SOURCE_DIR}/GenerateProjection.ps1" TO_NATIVE_PATH_LIST SCRIPT_PATH_NATIVE)
cmake_path(CONVERT "${SWIFT_WINRT_EXE}" TO_NATIVE_PATH_LIST SWIFT_WINRT_EXE_NATIVE)
cmake_path(CONVERT "${WINRTCOMPONENT_BINARY_DIR}/WinRTComponent.winmd" TO_NATIVE_PATH_LIST WINMD_NATIVE)
cmake_path(CONVERT "${CMAKE_CURRENT_BINARY_DIR}/Generated/Sources" TO_NATIVE_PATH_LIST OUTPUT_DIR_NATIVE)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SCRIPT_PATH_ARG}")
execute_process(
    COMMAND powershell.exe -File "${SCRIPT_PATH_NATIVE}"
        -SwiftWinRT "${SWIFT_WINRT_EXE_NATIVE}"
        -WinMD "${WINMD_NATIVE}"
        -OutputDir "${OUTPUT_DIR_NATIVE}"
    COMMAND_ERROR_IS_FATAL ANY)

# Build the support module if not already the case (by root CMakeLists.txt)
if(NOT TARGET WindowsRuntime)
    add_subdirectory(../Support "${CMAKE_CURRENT_BINARY_DIR}/Support")
endif()

# Build the Swift projection
# TODO(https://github.com/tristanlabelle/swift-winrt/issues/302): Fix linking issues
# add_subdirectory(
#     ${CMAKE_CURRENT_BINARY_DIR}/Generated/Sources
#     ${CMAKE_CURRENT_BINARY_DIR}/Generated/Build)