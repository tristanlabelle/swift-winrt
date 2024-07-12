FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG 0d40b6e92e18c7fc7eb2900cc1b55d9a140ec31c
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

add_library(CInterop INTERFACE)
target_include_directories(CInterop INTERFACE ${swift-dotnetmetadata_SOURCE_DIR}/Sources/CInterop/includes)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadataFormat/*.swift)
add_library(DotNetMetadataFormat STATIC ${SOURCES})
target_link_libraries(DotNetMetadataFormat PRIVATE CInterop)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadata/*.swift)
add_library(DotNetMetadata STATIC ${SOURCES})
target_link_libraries(DotNetMetadata PUBLIC DotNetMetadataFormat)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetXMLDocs/*.swift)
add_library(DotNetXMLDocs STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/WindowsMetadata/*.swift)
add_library(WindowsMetadata STATIC ${SOURCES})
target_link_libraries(WindowsMetadata PUBLIC DotNetMetadata)