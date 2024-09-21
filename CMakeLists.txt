cmake_minimum_required(VERSION 3.21.0)

project(SwiftWinRT LANGUAGES C Swift)

add_subdirectory(Support)

# InteropTests depends on SwiftWinRT.exe, so build it now 
message(STATUS "Configuring Generator subproject...")
execute_process(
    COMMAND ${CMAKE_COMMAND}
        -S "${CMAKE_CURRENT_SOURCE_DIR}/Generator"
        -B "${CMAKE_CURRENT_BINARY_DIR}/Generator"
        -G "${CMAKE_GENERATOR}"
        -D "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
        -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
        -D "CMAKE_Swift_COMPILER=${CMAKE_Swift_COMPILER}"
    COMMAND_ERROR_IS_FATAL ANY)

message(STATUS "Building Generator subproject...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --build "${CMAKE_CURRENT_BINARY_DIR}/Generator"
    COMMAND_ERROR_IS_FATAL ANY)
set(SWIFTWINRT_EXE "${CMAKE_CURRENT_BINARY_DIR}/Generator/Sources/SwiftWinRT/SwiftWinRT.exe")

# Now build InteropTests, which depends on SWIFTWINRT_EXE
add_subdirectory(InteropTests)