cmake_minimum_required(VERSION 3.21.0)

project(SwiftWinRT LANGUAGES C Swift)

add_subdirectory(Support)

# InteropTests depends on SwiftWinRT.exe, so build it now 
execute_process(
    COMMAND ${CMAKE_COMMAND}
        -S "${CMAKE_CURRENT_SOURCE_DIR}/Generator"
        -B "${CMAKE_CURRENT_BINARY_DIR}/Generator"
    COMMAND ${CMAKE_COMMAND}
        --build "${CMAKE_CURRENT_BINARY_DIR}/Generator"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Generator"
    COMMAND_ERROR_IS_FATAL ANY)
set(SWIFT_WINRT_EXE ${CMAKE_CURRENT_BINARY_DIR}/Generator/Sources/SwiftWinRT/SwiftWinRT.exe)

add_subdirectory(InteropTests) # Depends on SWIFT_WINRT_EXE