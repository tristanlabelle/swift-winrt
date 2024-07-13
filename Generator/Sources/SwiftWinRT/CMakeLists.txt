file(GLOB_RECURSE SOURCES *.swift)
add_executable(SwiftWinRT ${SOURCES})

file(GLOB RESOURCES Extensions/*_swift)
set(PACKAGERESOURCES_SWIFT ${CMAKE_CURRENT_BINARY_DIR}/PackageResources.swift)
file(WRITE ${PACKAGERESOURCES_SWIFT} "enum PackageResources {\n")
foreach(RESOURCE ${RESOURCES})
    get_filename_component(RESOURCE_NAME ${RESOURCE} NAME)
    file(READ ${RESOURCE} RESOURCE_HEX HEX)
    string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," RESOURCE_HEX ${RESOURCE_HEX})
    file(APPEND ${PACKAGERESOURCES_SWIFT} "    static let ${RESOURCE_NAME}: [UInt8] = [ ${RESOURCE_HEX} ]\n")
endforeach()
file(APPEND ${PACKAGERESOURCES_SWIFT} "}\n")
target_sources(SwiftWinRT PRIVATE ${PACKAGERESOURCES_SWIFT})

target_link_libraries(SwiftWinRT PRIVATE
    ArgumentParser Collections DotNetMetadata DotNetMetadataFormat WindowsMetadata
    CodeWriters ProjectionModel)