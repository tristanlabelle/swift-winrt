if("${PACKAGE_VERSION}" STREQUAL "")
    set(PACKAGE_VERSION "0.0.0")
endif()
set(PACKAGE_FILENAME "TristanLabelle.SwiftWinRT.${PACKAGE_VERSION}.nupkg")

if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
    set(EXE_SWITCH "-X64Exe")
else()
    set(EXE_SWITCH "-Arm64Exe")
endif()

add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_FILENAME}"
    COMMAND powershell.exe -File "${CMAKE_CURRENT_SOURCE_DIR}/Create-Package.ps1"
        "${EXE_SWITCH}" "$<TARGET_FILE:SwiftWinRT>"
        -MscorlibWinMD "${CMAKE_CURRENT_BINARY_DIR}/../mscorlib.winmd"
        -Version "${PACKAGE_VERSION}"
        -IntermediateDir "${CMAKE_CURRENT_BINARY_DIR}"
        -OutputPath "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_FILENAME}"
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/Create-Package.ps1"
        SwiftWinRT
        "${CMAKE_CURRENT_BINARY_DIR}/../mscorlib.winmd")

add_custom_target(NuGetPackage
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_FILENAME}")