add_library(WindowsRuntime_ABI STATIC)

target_include_directories(WindowsRuntime_ABI PUBLIC include)

file(GLOB SOURCES *.c)
target_sources(WindowsRuntime_ABI PRIVATE ${SOURCES})