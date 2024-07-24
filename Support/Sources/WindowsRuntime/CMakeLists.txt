file(GLOB_RECURSE SOURCES *.swift)
add_library(WindowsRuntime STATIC ${SOURCES})
target_link_libraries(WindowsRuntime PRIVATE COM WindowsRuntime_ABI SWRT_InternalABI)