FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG 606bf2b2be7f4cc1d82e4512517f0099bb1c27e3
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

add_subdirectory("${swift-dotnetmetadata_SOURCE_DIR}/Sources" "${CMAKE_CURRENT_BINARY_DIR}/Sources")
set(WINMDCORLIB_DIR "${swift-dotnetmetadata_SOURCE_DIR}/WindowsMetadataCoreLibrary" PARENT_SCOPE)