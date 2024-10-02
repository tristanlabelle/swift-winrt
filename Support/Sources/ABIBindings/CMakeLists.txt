file(GLOB_RECURSE SOURCES *.swift)
add_library(ABIBindings STATIC ${SOURCES})
# Workaround for https://gitlab.kitware.com/cmake/cmake/-/issues/26346
target_include_directories(ABIBindings INTERFACE "${CMAKE_CURRENT_BINARY_DIR}")