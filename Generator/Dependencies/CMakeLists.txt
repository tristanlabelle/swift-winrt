include(FetchContent)

add_compile_options(
    $<$<COMPILE_LANGUAGE:Swift>:-suppress-remarks>
    $<$<COMPILE_LANGUAGE:Swift>:-suppress-warnings>)

add_subdirectory(swift-argument-parser)
add_subdirectory(swift-collections)
add_subdirectory(swift-dotnetmetadata)