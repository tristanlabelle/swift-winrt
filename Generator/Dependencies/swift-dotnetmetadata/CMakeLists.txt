FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG 563f06526fffd2a375fa055138a82695900fb2b1
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadataCInterop/*.c)
add_library(DotNetMetadataCInterop STATIC ${SOURCES})
target_include_directories(DotNetMetadataCInterop PUBLIC ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadataCInterop/include)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadataFormat/*.swift)
add_library(DotNetMetadataFormat STATIC ${SOURCES})
target_link_libraries(DotNetMetadataFormat PUBLIC DotNetMetadataCInterop)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadata/*.swift)
add_library(DotNetMetadata STATIC ${SOURCES})
target_link_libraries(DotNetMetadata PUBLIC DotNetMetadataFormat)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetXMLDocs/*.swift)
add_library(DotNetXMLDocs STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/WindowsMetadata/*.swift)
add_library(WindowsMetadata STATIC ${SOURCES})
target_link_libraries(WindowsMetadata PUBLIC DotNetMetadata)
