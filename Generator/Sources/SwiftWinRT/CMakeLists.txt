add_subdirectory(Extensions)

file(GLOB_RECURSE SOURCES *.swift)
add_executable(SwiftWinRT ${SOURCES})
target_sources(SwiftWinRT PRIVATE "${PACKAGERESOURCES_SWIFT_FILE}")
target_link_libraries(SwiftWinRT PRIVATE
    ArgumentParser Collections DotNetMetadata DotNetMetadataFormat WindowsMetadata
    CodeWriters ProjectionModel)