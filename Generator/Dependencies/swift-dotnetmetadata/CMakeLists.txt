FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG 20790178c573dcc2238fa2af8680c0e6f23f7c5e
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

add_subdirectory("${swift-dotnetmetadata_SOURCE_DIR}/Sources" "${CMAKE_CURRENT_BINARY_DIR}/Sources")
set(WINMDCORLIB_DIR "${swift-dotnetmetadata_SOURCE_DIR}/WindowsMetadataCoreLibrary" PARENT_SCOPE)