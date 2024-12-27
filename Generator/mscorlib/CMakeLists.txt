# Assemble DotNetMetadata's mscorlib.il into mscorlib.winmd,
# which is required by the code generator.
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/mscorlib.winmd"
    COMMAND powershell.exe -File "${WINMDCORLIB_DIR}/Assemble.ps1"
        -SourcePath "${WINMDCORLIB_DIR}/mscorlib.il"
        -OutputPath "${CMAKE_CURRENT_BINARY_DIR}/mscorlib.winmd"
    DEPENDS
        "${WINMDCORLIB_DIR}/Assemble.ps1"
        "${WINMDCORLIB_DIR}/mscorlib.il")

add_custom_target(mscorlib ALL
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/mscorlib.winmd")

if(DEFINED GENERATOR_STAGING_DIR)
    add_custom_command(TARGET mscorlib POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_BINARY_DIR}/mscorlib.winmd"
            "${GENERATOR_STAGING_DIR}/mscorlib.winmd"
        BYPRODUCTS "${GENERATOR_STAGING_DIR}/mscorlib.winmd")
endif()