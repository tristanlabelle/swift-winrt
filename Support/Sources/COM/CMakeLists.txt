file(GLOB_RECURSE SOURCES *.swift)
add_library(COM STATIC ${SOURCES})
target_link_libraries(COM PUBLIC ABIBindings COM_ABI)
# Workaround for https://gitlab.kitware.com/cmake/cmake/-/issues/26346
target_include_directories(COM INTERFACE "${CMAKE_CURRENT_BINARY_DIR}")