cmake_minimum_required(VERSION 3.21.0)

if(NOT DEFINED CMAKE_PROJECT_NAME)
    project(InteropTests LANGUAGES C Swift)
endif()

if (NOT DEFINED SWIFTWINRT_EXE)
    message(FATAL_ERROR "SWIFTWINRT_EXE must be defined")
endif()
cmake_path(ABSOLUTE_PATH SWIFTWINRT_EXE NORMALIZE OUTPUT_VARIABLE SWIFTWINRT_EXE)

# Generating projection sources will depend on WinRTComponent.winmd, so build it now
set(WINRTCOMPONENT_IDL "${CMAKE_CURRENT_SOURCE_DIR}/WinRTComponent/WinRTComponent.idl")
set(WINRTCOMPONENT_WINMD "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.winmd")
include(WinRTComponent/GenerateWinMD.cmake)

# Generate Swift projection
message(STATUS "Generating Swift projection for WinRTComponent...")
cmake_path(CONVERT "${CMAKE_CURRENT_SOURCE_DIR}/GenerateProjection.ps1" TO_NATIVE_PATH_LIST SCRIPT_PATH_NATIVE)
cmake_path(CONVERT "${SWIFTWINRT_EXE}" TO_NATIVE_PATH_LIST SWIFTWINRT_EXE_NATIVE)
cmake_path(CONVERT "${WINRTCOMPONENT_WINMD}" TO_NATIVE_PATH_LIST WINRTCOMPONENT_WINMD_NATIVE)
cmake_path(CONVERT "${CMAKE_CURRENT_BINARY_DIR}/Generated/Sources" TO_NATIVE_PATH_LIST OUTPUT_DIR_NATIVE)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SCRIPT_PATH_ARG}")
execute_process(
    COMMAND powershell.exe -File "${SCRIPT_PATH_NATIVE}"
        -SwiftWinRT "${SWIFTWINRT_EXE_NATIVE}"
        -WinMD "${WINRTCOMPONENT_WINMD_NATIVE}"
        -OutputDir "${OUTPUT_DIR_NATIVE}"
    COMMAND_ERROR_IS_FATAL ANY)

# Define WinRTComponent build (requires the cl.exe compiler)
include(ExternalProject)
message(STATUS "Building WinRTComponent...")
ExternalProject_Add(WinRTComponent
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/WinRTComponent"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent"
    CMAKE_ARGS
        -D "WINRTCOMPONENT_WINMD=${WINRTCOMPONENT_WINMD}"
        -D "CMAKE_CXX_COMPILER=cl.exe"
        -D "CMAKE_CXX_FLAGS=/std:c++latest /W4 /EHsc"
    INSTALL_COMMAND ""
    TEST_COMMAND "")

# Build the support module if not already the case (by root CMakeLists.txt)
if(NOT TARGET WindowsRuntime)
    add_subdirectory(../Support "${CMAKE_CURRENT_BINARY_DIR}/Support")
endif()

# Build the Swift projection
# TODO(https://github.com/tristanlabelle/swift-winrt/issues/302): Fix linking issues
# add_subdirectory(
#     ${CMAKE_CURRENT_BINARY_DIR}/Generated/Sources
#     ${CMAKE_CURRENT_BINARY_DIR}/Generated/Build)