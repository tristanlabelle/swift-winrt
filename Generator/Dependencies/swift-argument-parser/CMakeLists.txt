FetchContent_Declare(
    swift-argument-parser
    GIT_REPOSITORY https://github.com/apple/swift-argument-parser.git
    GIT_TAG 8f4d2753f0e4778c76d5f05ad16c74f707390531 # 1.2.3
    SOURCE_SUBDIR "don't use cmakelists")
FetchContent_MakeAvailable(swift-argument-parser)

file(GLOB_RECURSE SOURCES ${swift-argument-parser_SOURCE_DIR}/Sources/ArgumentParserToolInfo/*.swift)
add_library(ArgumentParserToolInfo STATIC ${SOURCES})

file(GLOB_RECURSE SOURCES ${swift-argument-parser_SOURCE_DIR}/Sources/ArgumentParser/*.swift)
add_library(ArgumentParser STATIC ${SOURCES})
target_link_libraries(ArgumentParser PRIVATE ArgumentParserToolInfo)