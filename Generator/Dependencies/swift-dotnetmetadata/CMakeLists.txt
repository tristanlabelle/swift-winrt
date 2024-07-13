FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG 4e01ac1e61fbc293ebfd01139e840453b3714a8a
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/CInterop/*.c)
add_library(CInterop STATIC ${SOURCES})
target_include_directories(CInterop PUBLIC ${swift-dotnetmetadata_SOURCE_DIR}/Sources/CInterop/include)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadataFormat/*.swift)
add_library(DotNetMetadataFormat STATIC ${SOURCES})
target_link_libraries(DotNetMetadataFormat PUBLIC CInterop)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadata/*.swift)
add_library(DotNetMetadata STATIC ${SOURCES})
target_link_libraries(DotNetMetadata PUBLIC DotNetMetadataFormat)

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/DotNetXMLDocs/*.swift)
add_library(DotNetXMLDocs STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift-dotnetmetadata_SOURCE_DIR}/Sources/WindowsMetadata/*.swift)
add_library(WindowsMetadata STATIC ${SOURCES})
target_link_libraries(WindowsMetadata PUBLIC DotNetMetadata)