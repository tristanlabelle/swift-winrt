add_library(WindowsRuntime STATIC)

file(GLOB_RECURSE SOURCES *.swift)
target_sources(WindowsRuntime PRIVATE ${SOURCES})

target_link_libraries(WindowsRuntime PRIVATE COM WindowsRuntime_ABI)