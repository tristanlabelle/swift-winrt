cmake_minimum_required(VERSION 3.21.0)

project(SwiftWinRT LANGUAGES C Swift)

if("${CMAKE_EXPORT_COMPILE_COMMANDS}" STREQUAL "")
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

add_subdirectory(CompilerCheck)

# Building InteropTests will require running the code generator,
# so we configure and build it as a subproject.
message(STATUS "Configuring Generator as subproject...")
execute_process(
    COMMAND ${CMAKE_COMMAND}
        -S "${CMAKE_CURRENT_SOURCE_DIR}/Generator"
        -B "${CMAKE_CURRENT_BINARY_DIR}/Generator"
        -G "${CMAKE_GENERATOR}"
        -D "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
        -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
        -D "CMAKE_Swift_COMPILER=${CMAKE_Swift_COMPILER}"
        -D "CMAKE_EXPORT_COMPILE_COMMANDS=${CMAKE_EXPORT_COMPILE_COMMANDS}"
    COMMAND_ERROR_IS_FATAL ANY)

message(STATUS "Building Generator as subproject...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --build "${CMAKE_CURRENT_BINARY_DIR}/Generator"
    COMMAND_ERROR_IS_FATAL ANY)

add_subdirectory(Support)

# Now build InteropTests, which depends on SWIFTWINRT_EXE
set(SWIFTWINRT_EXE "${CMAKE_CURRENT_BINARY_DIR}/Generator/SwiftWinRT.exe")
add_subdirectory(InteropTests)
