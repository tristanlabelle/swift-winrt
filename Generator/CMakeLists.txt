cmake_minimum_required(VERSION 3.21.0)

project(SwiftWinRT LANGUAGES C Swift)

add_subdirectory(Dependencies)

set(SWIFTWINRT_EXE_STAGING_DIR "${CMAKE_CURRENT_BINARY_DIR}")
add_subdirectory(Sources)
