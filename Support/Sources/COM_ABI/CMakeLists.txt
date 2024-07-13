file(GLOB SOURCES *.c)
add_library(COM_ABI STATIC ${SOURCES})
target_include_directories(COM_ABI PUBLIC include)