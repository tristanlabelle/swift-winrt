FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG e99579588a5a2c8b897299587ad5d1ed6b735d85
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

add_subdirectory("${swift-dotnetmetadata_SOURCE_DIR}/Sources" "${CMAKE_CURRENT_BINARY_DIR}/Sources")
set(WINMDCORLIB_DIR "${swift-dotnetmetadata_SOURCE_DIR}/WindowsMetadataCoreLibrary" PARENT_SCOPE)