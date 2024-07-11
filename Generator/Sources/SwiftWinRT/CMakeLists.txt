file(GLOB_RECURSE SOURCES *.swift)
file(GLOB RESOURCES Extensions/*_swift)
add_executable(SwiftWinRT ${SOURCES})
target_link_libraries(SwiftWinRT PRIVATE CodeWriters ProjectionModel)