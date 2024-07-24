file(GLOB SOURCES *.c)
add_library(SWRT_Core INTERFACE)
target_include_directories(SWRT_Core PUBLIC include)