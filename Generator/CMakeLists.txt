cmake_minimum_required(VERSION 3.21.0)

project(SwiftWinRT LANGUAGES C Swift)

include(Dependencies.cmake)

add_subdirectory(CodeWriters)
add_subdirectory(ProjectionModel)
add_subdirectory(SwiftWinRT)