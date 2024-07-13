FetchContent_Declare(
    swift-collections
    GIT_REPOSITORY https://github.com/apple/swift-collections.git
    GIT_TAG d029d9d39c87bed85b1c50adee7c41795261a192 # 1.0.6
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-collections)

file(GLOB_RECURSE SOURCES ${swift-collections_SOURCE_DIR}/Sources/DequeModule/*.swift)
add_library(DequeModule STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift-collections_SOURCE_DIR}/Sources/OrderedCollections/*.swift)
add_library(OrderedCollections STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift-collections_SOURCE_DIR}/Sources/Collections/*.swift)
add_library(Collections STATIC ${SOURCES})
target_link_libraries(Collections PRIVATE DequeModule OrderedCollections)