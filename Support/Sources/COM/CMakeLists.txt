add_library(COM STATIC)

file(GLOB_RECURSE SOURCES *.swift)
target_sources(COM PRIVATE ${SOURCES})

target_link_libraries(COM PRIVATE WindowsRuntime_ABI)