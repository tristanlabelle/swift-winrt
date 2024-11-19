# Generates the WinRTComponent.winmd file from the WinRTComponent.idl file.
function(generate_winrtcomponent_winmd)
    cmake_parse_arguments("ARG" "" "IDL;WINMD" "" ${ARGN})
    if("${ARG_IDL}" STREQUAL "")
        message(FATAL_ERROR "IDL argument is required")
    endif()

    if("${ARG_WINMD}" STREQUAL "")
        message(FATAL_ERROR "WINMD argument is required")
    endif()

    cmake_path(CONVERT "$ENV{WindowsSdkDir}References\\$ENV{WindowsSDKVersion}" TO_CMAKE_PATH_LIST WINSDK_REFERENCES_DIR NORMALIZE)

    # Find the reference assemblies we're interested in, assuming there is a single version of each
    file(GLOB FOUNDATIONCONTRACT_WINMD "${WINSDK_REFERENCES_DIR}/Windows.Foundation.FoundationContract/*/Windows.Foundation.FoundationContract.winmd")
    if("${FOUNDATIONCONTRACT_WINMD}" STREQUAL "" OR "${FOUNDATIONCONTRACT_WINMD}" MATCHES ";")
        message(FATAL_ERROR "Zero or multiple Windows.Foundation.FoundationContract assemblies found under ${WINSDK_REFERENCES_DIR}")
    endif()

    file(GLOB UNIVERSALAPICONTRACT_WINMD "${WINSDK_REFERENCES_DIR}/Windows.Foundation.UniversalApiContract/*/Windows.Foundation.UniversalApiContract.winmd")
    if("${UNIVERSALAPICONTRACT_WINMD}" STREQUAL "" OR "${UNIVERSALAPICONTRACT_WINMD}" MATCHES ";")
        message(FATAL_ERROR "Zero or multiple Windows.Foundation.UniversalApiContract assemblies found under ${WINSDK_REFERENCES_DIR}")
    endif()

    message(STATUS "Generating WinRTComponent.winmd...")
    set(MIDLRT_EXE_NATIVE "$ENV{WindowsSdkVerBinPath}$ENV{VSCMD_ARG_HOST_ARCH}\\midlrt.exe")
    cmake_path(GET FOUNDATIONCONTRACT_WINMD PARENT_PATH FOUNDATIONCONTRACT_DIR)
    cmake_path(CONVERT "${FOUNDATIONCONTRACT_DIR}" TO_NATIVE_PATH_LIST METADATA_DIR_NATIVE)
    cmake_path(CONVERT "${FOUNDATIONCONTRACT_WINMD}" TO_NATIVE_PATH_LIST FOUNDATIONCONTRACT_WINMD_NATIVE)
    cmake_path(CONVERT "${UNIVERSALAPICONTRACT_WINMD}" TO_NATIVE_PATH_LIST UNIVERSALAPICONTRACT_WINMD_NATIVE)
    cmake_path(CONVERT "${ARG_WINMD}" TO_NATIVE_PATH_LIST WINRTCOMPONENT_WINMD_NATIVE)
    string(REPLACE ".winmd" ".h" WINRTCOMPONENT_H_NATIVE "${WINRTCOMPONENT_WINMD_NATIVE}")
    cmake_path(CONVERT "${ARG_IDL}" TO_NATIVE_PATH_LIST WINRTCOMPONENT_IDL_NATIVE)
    execute_process(
        COMMAND "${MIDLRT_EXE_NATIVE}"
            /W1 /nologo /nomidl
            /metadata_dir "${METADATA_DIR_NATIVE}"
            /reference "${FOUNDATIONCONTRACT_WINMD_NATIVE}"
            /reference "${UNIVERSALAPICONTRACT_WINMD_NATIVE}"
            /winmd "${WINRTCOMPONENT_WINMD_NATIVE}.timestamped"
            /header "${WINRTCOMPONENT_H_NATIVE}"
            "${WINRTCOMPONENT_IDL_NATIVE}"
        COMMAND_ERROR_IS_FATAL ANY)

    # Remove the timestamp from the generated WinRTComponent.winmd file for cachability
    # TODO: We also need to zero the random "mvid" (module version id) field of the module metadata table :/
    execute_process(
        COMMAND powershell.exe -File "${CMAKE_CURRENT_SOURCE_DIR}/Clear-PEDateTimeStamp.ps1"
            -In "${WINRTCOMPONENT_WINMD_NATIVE}.timestamped"
            -Out "${WINRTCOMPONENT_WINMD_NATIVE}"
        COMMAND_ERROR_IS_FATAL ANY)
endfunction()