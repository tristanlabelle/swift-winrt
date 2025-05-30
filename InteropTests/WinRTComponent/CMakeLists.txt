# Support using this directory as a standalone project or as a subdirectory.
if("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    cmake_minimum_required(VERSION 3.21.0)
    project(WinRTComponent LANGUAGES CXX Swift)
endif()

if (NOT DEFINED SWIFTWINRT_EXE)
    message(FATAL_ERROR "SWIFTWINRT_EXE must be defined")
endif()
cmake_path(ABSOLUTE_PATH SWIFTWINRT_EXE NORMALIZE)

if(NOT DEFINED PROJECTION_DIR)
    set(PROJECTION_DIR "${CMAKE_CURRENT_BINARY_DIR}/Projection/Sources")
endif()

# Generate the WinRTComponent.winmd file
message(STATUS "Building WinRTComponent.winmd as a subproject...")
execute_process(
    COMMAND ${CMAKE_COMMAND}
        -S "${CMAKE_CURRENT_SOURCE_DIR}/WinMD"
        -B "${CMAKE_CURRENT_BINARY_DIR}/WinMD"
        -G "${CMAKE_GENERATOR}"
    COMMAND_ERROR_IS_FATAL ANY)
execute_process(
    COMMAND ${CMAKE_COMMAND} --build "${CMAKE_CURRENT_BINARY_DIR}/WinMD"
    COMMAND_ERROR_IS_FATAL ANY)

set(WINRTCOMPONENT_WINMD "${CMAKE_CURRENT_BINARY_DIR}/WinMD/WinRTComponent.winmd")

# Generate Swift projection
message(STATUS "Generating Swift projection for WinRTComponent...")
include(GenerateProjection.cmake)
generate_projection(
    SWIFTWINRT_EXE "${SWIFTWINRT_EXE}"
    WINRTCOMPONENT_WINMD "${WINRTCOMPONENT_WINMD}"
    PROJECTION_JSON "${CMAKE_CURRENT_SOURCE_DIR}/Projection.json"
    PROJECTION_DIR "${PROJECTION_DIR}")

# Define the dll build (requires cl.exe)
include(ExternalProject)
ExternalProject_Add(WinRTComponentDll
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Dll"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/Dll"
    CMAKE_ARGS
        -D "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
        -D "WINRTCOMPONENT_WINMD=${WINRTCOMPONENT_WINMD}"
        -D "CMAKE_CXX_COMPILER=cl.exe"
        -D "CMAKE_CXX_FLAGS=/std:c++latest /W4 /EHsc"
    INSTALL_COMMAND ""
    TEST_COMMAND "")

# Define the projection build
add_subdirectory("${PROJECTION_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/Projection/Build")