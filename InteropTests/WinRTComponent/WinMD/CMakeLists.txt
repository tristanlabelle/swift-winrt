# Support using this directory as a standalone project or as a subdirectory.
if("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    cmake_minimum_required(VERSION 3.21.0)
    project(WinMD LANGUAGES NONE)
endif()

# Locate files we need from the Windows SDK
if("$ENV{VSCMD_ARG_HOST_ARCH}" STREQUAL "" OR "$ENV{WindowsSdkDir}" STREQUAL "" OR "$ENV{WindowsSDKVersion}" STREQUAL "")
    message(FATAL_ERROR "CMake should be called within a VS developer command prompt.")
endif()

cmake_path(CONVERT "$ENV{WindowsSdkDir}References\\$ENV{WindowsSDKVersion}" TO_CMAKE_PATH_LIST WINSDK_REFERENCES_DIR NORMALIZE)

file(GLOB FOUNDATIONCONTRACT_WINMD "${WINSDK_REFERENCES_DIR}/Windows.Foundation.FoundationContract/*/Windows.Foundation.FoundationContract.winmd")
if("${FOUNDATIONCONTRACT_WINMD}" STREQUAL "" OR "${FOUNDATIONCONTRACT_WINMD}" MATCHES ";")
    message(FATAL_ERROR "Zero or multiple Windows.Foundation.FoundationContract assemblies found under ${WINSDK_REFERENCES_DIR}")
endif()
cmake_path(GET FOUNDATIONCONTRACT_WINMD PARENT_PATH FOUNDATIONCONTRACT_DIR)

file(GLOB UNIVERSALAPICONTRACT_WINMD "${WINSDK_REFERENCES_DIR}/Windows.Foundation.UniversalApiContract/*/Windows.Foundation.UniversalApiContract.winmd")
if("${UNIVERSALAPICONTRACT_WINMD}" STREQUAL "" OR "${UNIVERSALAPICONTRACT_WINMD}" MATCHES ";")
    message(FATAL_ERROR "Zero or multiple Windows.Foundation.UniversalApiContract assemblies found under ${WINSDK_REFERENCES_DIR}")
endif()

cmake_path(CONVERT "$ENV{WindowsSdkVerBinPath}$ENV{VSCMD_ARG_HOST_ARCH}\\midlrt.exe" TO_CMAKE_PATH_LIST MIDLRT_EXE NORMALIZE)

# Generate a single idl source file that includes all idl files in the directory.
set(IDL_SOURCE "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.idl")
file(GLOB IDL_SOURCE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/*.idl")
set(IDL_SOURCE_CODE "")
foreach(IDL_SOURCE_FILE IN LISTS IDL_SOURCE_FILES)
    set(IDL_SOURCE_CODE "${IDL_SOURCE_CODE}#include \"${IDL_SOURCE_FILE}\"\n")
endforeach()
file(WRITE "${IDL_SOURCE}" "${IDL_SOURCE_CODE}")

set(OUTPUT_WINMD "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.winmd")
set(OUTPUT_HEADER "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.h")
set(OUTPUT_XMLDOCS "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.xml")

# Generate the WinMD
add_custom_command(
    OUTPUT "${OUTPUT_WINMD}" "${OUTPUT_HEADER}"
    DEPENDS ${IDL_SOURCES} ${FOUNDATIONCONTRACT_WINMD} ${UNIVERSALAPICONTRACT_WINMD}
    COMMAND "$<SHELL_PATH:${MIDLRT_EXE}>"
        /W1 /nologo /nomidl
        /metadata_dir "$<SHELL_PATH:${FOUNDATIONCONTRACT_DIR}>"
        /reference "$<SHELL_PATH:${FOUNDATIONCONTRACT_WINMD}>"
        /reference "$<SHELL_PATH:${UNIVERSALAPICONTRACT_WINMD}>"
        /winmd "$<SHELL_PATH:${OUTPUT_WINMD}>"
        /header "$<SHELL_PATH:${OUTPUT_HEADER}>"
        "$<SHELL_PATH:${IDL_SOURCE}>")

add_custom_command(
    OUTPUT "${OUTPUT_XMLDOCS}"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/WinRTComponent.xml"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/WinRTComponent.xml"
        "${CMAKE_CURRENT_BINARY_DIR}/")

add_custom_target(WinRTComponentWinMD ALL
    DEPENDS "${OUTPUT_WINMD}" "${OUTPUT_HEADER}" "${OUTPUT_XMLDOCS}")
