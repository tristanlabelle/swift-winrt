file(GLOB_RECURSE SOURCES *.swift)
add_library(WindowsRuntime STATIC ${SOURCES})
target_link_libraries(WindowsRuntime PUBLIC COM WindowsRuntime_ABI)
