# Invokes SwiftWinRT to generate a Swift projection for a WinRT component
# This file can be called as a CMake script.
function(generate_projection)
    cmake_parse_arguments("ARG" "" "SWIFTWINRT_EXE;WINRTCOMPONENT_WINMD;PROJECTION_JSON;PROJECTION_DIR;SUPPORT_MODULE_DIR" "" ${ARGN})

    if ("${ARG_SWIFTWINRT_EXE}" STREQUAL "")
        message(FATAL_ERROR "SWIFTWINRT_EXE argument is required")
    endif()

    if("${ARG_WINRTCOMPONENT_WINMD}" STREQUAL "")
        message(FATAL_ERROR "WINRTCOMPONENT_WINMD argument is required")
    endif()

    if("${ARG_PROJECTION_JSON}" STREQUAL "")
        message(FATAL_ERROR "PROJECTION_JSON argument is required")
    endif()

    if("${ARG_PROJECTION_DIR}" STREQUAL "")
        message(FATAL_ERROR "PROJECTION_DIR argument is required")
    endif()

    if("${ARG_SUPPORT_MODULE_DIR}" STREQUAL "")
        message(FATAL_ERROR "SUPPORT_MODULE_DIR argument is required")
    endif()

    cmake_path(CONVERT "${ARG_PROJECTION_JSON}" TO_NATIVE_PATH_LIST PROJECTION_JSON_NATIVE)
    string(REPLACE "\\" "" WINDOWS_SDK_VERSION "$ENV{WindowsSDKVersion}") # Remove trailing slash
    cmake_path(CONVERT "${ARG_WINRTCOMPONENT_WINMD}" TO_NATIVE_PATH_LIST WINRTCOMPONENT_WINMD_NATIVE)
    cmake_path(CONVERT "${ARG_SUPPORT_MODULE_DIR}" TO_NATIVE_PATH_LIST SUPPORT_MODULE_DIR_NATIVE)
    cmake_path(CONVERT "${ARG_PROJECTION_DIR}" TO_NATIVE_PATH_LIST PROJECTION_DIR_NATIVE)
    execute_process(
        COMMAND "${ARG_SWIFTWINRT_EXE}"
            --config "${PROJECTION_JSON_NATIVE}"
            --winsdk "${WINDOWS_SDK_VERSION}"
            --reference "${WINRTCOMPONENT_WINMD_NATIVE}"
            --spm
            --support "${SUPPORT_MODULE_DIR_NATIVE}"
            --cmakelists
            --out "${PROJECTION_DIR_NATIVE}"
            --out-manifest "${PROJECTION_DIR_NATIVE}\\WinRTComponent.manifest"
        COMMAND_ERROR_IS_FATAL ANY)
endfunction()

# Support running as a script
if(CMAKE_SCRIPT_MODE_FILE AND NOT CMAKE_PARENT_LIST_FILE)
    generate_projection(
        SWIFTWINRT_EXE "${SWIFTWINRT_EXE}"
        WINRTCOMPONENT_WINMD "${WINRTCOMPONENT_WINMD}"
        PROJECTION_JSON "${PROJECTION_JSON}"
        PROJECTION_DIR "${PROJECTION_DIR}"
        SUPPORT_MODULE_DIR "${SUPPORT_MODULE_DIR}")
endif()