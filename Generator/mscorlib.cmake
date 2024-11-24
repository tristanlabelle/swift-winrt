add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/mscorlib.winmd"
    COMMAND powershell.exe -File "${WINMDCORLIB_DIR}/Assemble.ps1"
        -SourcePath "${WINMDCORLIB_DIR}/mscorlib.il"
        -OutputPath "${CMAKE_CURRENT_BINARY_DIR}/mscorlib.winmd"
    DEPENDS
        "${WINMDCORLIB_DIR}/Assemble.ps1"
        "${WINMDCORLIB_DIR}/mscorlib.il")

add_custom_target(mscorlib ALL
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/mscorlib.winmd")