FetchContent_Declare(
    swift-dotnetmetadata
    GIT_REPOSITORY https://github.com/tristanlabelle/swift-dotnetmetadata.git
    GIT_TAG fee20ee55c7da6900b0eb0fbada3bc8006bfa455
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-dotnetmetadata)

add_subdirectory("${swift-dotnetmetadata_SOURCE_DIR}/Sources" "${CMAKE_CURRENT_BINARY_DIR}/Sources")