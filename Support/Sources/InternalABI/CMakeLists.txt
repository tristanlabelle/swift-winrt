file(GLOB SOURCES *.c)
add_library(SWRT_CoreInterop STATIC ${SOURCES})
target_include_directories(SWRT_CoreInterop PUBLIC include)
target_link_libraries(SWRT_CoreInterop PUBLIC SWRT_Core)