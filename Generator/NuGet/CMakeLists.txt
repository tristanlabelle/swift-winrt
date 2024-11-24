add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TristanLabelle.SwiftWinRT.0.0.0.nupkg"
    COMMAND powershell.exe -File "${CMAKE_CURRENT_SOURCE_DIR}/Create-Package.ps1"
        -NativeExe "$<TARGET_FILE:SwiftWinRT>"
        -MscorlibPath "${CMAKE_CURRENT_BINARY_DIR}/../mscorlib.winmd"
        -Version 0.0.0
        -OutputPath "${CMAKE_CURRENT_BINARY_DIR}/TristanLabelle.SwiftWinRT.0.0.0.nupkg"
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/Create-Package.ps1"
        SwiftWinRT
        "${CMAKE_CURRENT_BINARY_DIR}/../mscorlib.winmd")

add_custom_target(NuGetPackage
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/TristanLabelle.SwiftWinRT.0.0.0.nupkg")