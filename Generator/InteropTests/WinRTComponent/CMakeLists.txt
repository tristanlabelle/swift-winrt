# Support using this directory as a standalone project or as a subdirectory.
if("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    cmake_minimum_required(VERSION 3.21.0)
    project(WinRTComponent LANGUAGES CXX)
endif()

if (NOT DEFINED SWIFTWINRT_EXE)
    message(FATAL_ERROR "SWIFTWINRT_EXE must be defined")
endif()
cmake_path(ABSOLUTE_PATH SWIFTWINRT_EXE NORMALIZE)

if(NOT DEFINED PROJECTION_DIR)
    set(PROJECTION_DIR "${CMAKE_CURRENT_BINARY_DIR}/Projection/Sources")
endif()

# Generate the WinRTComponent.winmd file
set(WINRTCOMPONENT_WINMD "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.winmd")
include(GenerateWinMD.cmake)
generate_winrtcomponent_winmd(
    IDL "${CMAKE_CURRENT_SOURCE_DIR}/IDL/WinRTComponent.idl"
    WINMD "${WINRTCOMPONENT_WINMD}")

# Generate Swift projection
message(STATUS "Generating Swift projection for WinRTComponent...")
include(GenerateProjection.cmake)
generate_projection(
    SWIFTWINRT_EXE "${SWIFTWINRT_EXE}"
    WINRTCOMPONENT_WINMD "${WINRTCOMPONENT_WINMD}"
    PROJECTION_JSON "${CMAKE_CURRENT_SOURCE_DIR}/projection.json"
    PROJECTION_DIR "${PROJECTION_DIR}")

# Define the dll build (requires cl.exe)
include(ExternalProject)
ExternalProject_Add(WinRTComponent
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Dll"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/Dll"
    CMAKE_ARGS
        -D "WINRTCOMPONENT_WINMD=${WINRTCOMPONENT_WINMD}"
        -D "CMAKE_CXX_COMPILER=cl.exe"
        -D "CMAKE_CXX_FLAGS=/std:c++latest /W4 /EHsc"
    INSTALL_COMMAND ""
    TEST_COMMAND "")

# Define the projection build
# TODO(https://github.com/tristanlabelle/swift-winrt/issues/302): Fix linking issues
# add_subdirectory(
#     ${CMAKE_CURRENT_BINARY_DIR}/Projection/Sources
#     ${CMAKE_CURRENT_BINARY_DIR}/Projection/Build)