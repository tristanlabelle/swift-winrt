# Support using this directory as a standalone project or as a subdirectory.
if("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    cmake_minimum_required(VERSION 3.21.0)

    project(InteropTests LANGUAGES C Swift)
endif()

if (NOT DEFINED SWIFTWINRT_EXE)
    message(FATAL_ERROR "SWIFTWINRT_EXE must be defined")
endif()
cmake_path(ABSOLUTE_PATH SWIFTWINRT_EXE NORMALIZE)

# Build the support module if not already the case (by root CMakeLists.txt)
if(NOT TARGET WindowsRuntime)
    execute_process(
        COMMAND git.exe -C "${CMAKE_CURRENT_SOURCE_DIR}" rev-parse --path-format=absolute --show-toplevel
        OUTPUT_VARIABLE REPO_ROOT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY)
    add_subdirectory("${REPO_ROOT}/Sources" "${CMAKE_CURRENT_BINARY_DIR}/Support")
endif()

add_subdirectory(WinRTComponent)
