FetchContent_Declare(
    Swift_Argument_Parser
    GIT_REPOSITORY https://github.com/apple/swift-argument-parser.git
    GIT_TAG 8f4d2753f0e4778c76d5f05ad16c74f707390531) # 1.2.3
FetchContent_MakeAvailable(Swift_Argument_Parser)

file(GLOB_RECURSE SOURCES ${swift_argument_parser_SOURCE_DIR}/*.swift)
add_library(ArgumentParser STATIC ${SOURCES})

FetchContent_Declare(
    Swift_Collections
    GIT_REPOSITORY https://github.com/apple/swift-collections.git
    GIT_TAG d029d9d39c87bed85b1c50adee7c41795261a192) # 1.0.6
FetchContent_MakeAvailable(Swift_Collections)

file(GLOB_RECURSE SOURCES ${swift_collections_SOURCE_DIR}/*.swift)
add_library(Collections STATIC ${SOURCES})

FetchContent_Declare(
    Swift_DotNetMetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG 0d40b6e92e18c7fc7eb2900cc1b55d9a140ec31c)
FetchContent_MakeAvailable(Swift_DotNetMetadata)

file(GLOB_RECURSE SOURCES ${swift_dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadataFormat/*.swift)
add_library(DotNetMetadataFormat STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift_dotnetmetadata_SOURCE_DIR}/Sources/DotNetMetadata/*.swift)
add_library(DotNetMetadata STATIC ${SOURCES})
target_link_libraries(DotNetMetadata PUBLIC DotNetMetadataFormat)

file(GLOB_RECURSE SOURCES ${swift_dotnetmetadata_SOURCE_DIR}/Sources/DotNetXMLDocs/*.swift)
add_library(DotNetXMLDocs STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift_dotnetmetadata_SOURCE_DIR}/Sources/WindowsMetadata/*.swift)
add_library(WindowsMetadata STATIC ${SOURCES})
target_link_libraries(WindowsMetadata PUBLIC DotNetMetadata)