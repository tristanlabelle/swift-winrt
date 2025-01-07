FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG b4870688be31d889ed51da9beac466ede9f366dd
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

add_subdirectory("${swift-dotnetmetadata_SOURCE_DIR}/Sources" "${CMAKE_CURRENT_BINARY_DIR}/Sources")
set(WINMDCORLIB_DIR "${swift-dotnetmetadata_SOURCE_DIR}/WindowsMetadataCoreLibrary" PARENT_SCOPE)