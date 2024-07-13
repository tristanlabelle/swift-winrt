file(GLOB SOURCES *.c)
add_library(WindowsRuntime_ABI STATIC ${SOURCES})
target_include_directories(WindowsRuntime_ABI PUBLIC include)
target_link_libraries(WindowsRuntime_ABI PUBLIC COM_ABI)