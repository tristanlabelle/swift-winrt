cmake_minimum_required(VERSION 3.21.0)

project(SwiftWinRT LANGUAGES C Swift)

add_subdirectory(Support)

include(ExternalProject)

ExternalProject_Add(Generator
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Generator
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/Generator
    INSTALL_COMMAND "")
set(SWIFT_WINRT_EXE ${CMAKE_CURRENT_BINARY_DIR}/Generator/Sources/SwiftWinRT/SwiftWinRT.exe)

ExternalProject_Add(InteropTests
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/InteropTests
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/InteropTests
    CMAKE_ARGS -DSWIFT_WINRT_EXE=${SWIFT_WINRT_EXE}
    INSTALL_COMMAND ""
    DEPENDS Generator)