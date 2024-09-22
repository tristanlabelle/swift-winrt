# Support using this directory as a standalone project or as a subdirectory.
if("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    cmake_minimum_required(VERSION 3.21.0)

    project(InteropTests LANGUAGES C Swift)
endif()

if (NOT DEFINED SWIFTWINRT_EXE)
    message(FATAL_ERROR "SWIFTWINRT_EXE must be defined")
endif()
cmake_path(ABSOLUTE_PATH SWIFTWINRT_EXE NORMALIZE OUTPUT_VARIABLE SWIFTWINRT_EXE)

set(REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")

# Generating projection sources will depend on WinRTComponent.winmd, so build it now
include(WinRTComponent/GenerateWinMD.cmake)
set(WINRTCOMPONENT_WINMD "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.winmd")
generate_winrtcomponent_winmd(
    IDL "${CMAKE_CURRENT_SOURCE_DIR}/WinRTComponent/WinRTComponent.idl"
    WINMD "${WINRTCOMPONENT_WINMD}")

# Generate Swift projection
message(STATUS "Generating Swift projection for WinRTComponent...")
include(GenerateProjection.cmake)
generate_projection(
    SWIFTWINRT_EXE "${SWIFTWINRT_EXE}"
    WINRTCOMPONENT_WINMD "${WINRTCOMPONENT_WINMD}"
    PROJECTION_JSON "${CMAKE_CURRENT_SOURCE_DIR}/projection.json"
    PROJECTION_DIR "${CMAKE_CURRENT_BINARY_DIR}/Projection/Sources"
    SPM_SUPPORT_PACKAGE_DIR "${REPO_ROOT}")

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
    add_subdirectory("${REPO_ROOT}/Support/Sources" "${CMAKE_CURRENT_BINARY_DIR}/Support")
endif()

# Build the Swift projection
# TODO(https://github.com/tristanlabelle/swift-winrt/issues/302): Fix linking issues
# add_subdirectory(
#     ${CMAKE_CURRENT_BINARY_DIR}/Projection/Sources
#     ${CMAKE_CURRENT_BINARY_DIR}/Projection/Build)