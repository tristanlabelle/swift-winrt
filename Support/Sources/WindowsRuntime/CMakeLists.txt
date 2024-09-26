file(GLOB_RECURSE SOURCES *.swift)
add_library(WindowsRuntime STATIC ${SOURCES})
target_link_libraries(WindowsRuntime PUBLIC COM WindowsRuntime_ABI)
target_link_libraries(WindowsRuntime PRIVATE SWRT_InternalABI)

# Workaround for CMake not propagating include dirs
target_include_directories(WindowsRuntime INTERFACE "$<TARGET_FILE_DIR:ABIBindings>")