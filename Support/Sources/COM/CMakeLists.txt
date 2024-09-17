file(GLOB_RECURSE SOURCES *.swift)
add_library(COM STATIC ${SOURCES})
target_link_libraries(COM PUBLIC ABIBindings COM_ABI)
target_link_libraries(COM PRIVATE SWRT_InternalABI)