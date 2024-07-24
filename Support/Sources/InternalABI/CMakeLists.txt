file(GLOB SOURCES *.c)
add_library(SWRT_InternalABI STATIC ${SOURCES})
target_include_directories(SWRT_InternalABI PUBLIC include)
target_link_libraries(SWRT_InternalABI PUBLIC WindowsRuntime_ABI)