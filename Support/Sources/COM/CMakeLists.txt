file(GLOB_RECURSE SOURCES *.swift)
add_library(COM STATIC ${SOURCES})
target_link_libraries(COM PRIVATE COM_ABI SWRT_InternalABI)