add_subdirectory(Extensions)

file(GLOB_RECURSE SOURCES *.swift)
add_executable(SwiftWinRT ${SOURCES})
target_sources(SwiftWinRT PRIVATE "${PACKAGERESOURCES_SWIFT_FILE}")
target_link_libraries(SwiftWinRT PRIVATE
    ArgumentParser Collections DotNetMetadata DotNetMetadataFormat WindowsMetadata
    CodeWriters ProjectionModel)

if(DEFINED SWIFTWINRT_EXE_STAGING_DIR)
    add_custom_command(TARGET SwiftWinRT
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_BINARY_DIR}/SwiftWinRT.exe"
            "${SWIFTWINRT_EXE_STAGING_DIR}/SwiftWinRT.exe"
        BYPRODUCTS "${SWIFTWINRT_EXE_STAGING_DIR}/SwiftWinRT.exe")
endif()