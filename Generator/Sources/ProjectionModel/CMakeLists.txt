file(GLOB_RECURSE SOURCES *.swift)
add_library(ProjectionModel STATIC ${SOURCES})
target_link_libraries(ProjectionModel PUBLIC
    Collections
    CodeWriters
    DotNetMetadata
    DotNetMetadataFormat
    DotNetXMLDocs
    DotNetXMLDocsFromMetadata
    WindowsMetadata)