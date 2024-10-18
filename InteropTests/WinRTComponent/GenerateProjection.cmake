# Invokes SwiftWinRT to generate a Swift projection for a WinRT component
# This file can be called as a CMake script.
function(generate_projection)
    cmake_parse_arguments("ARG" "" "SWIFTWINRT_EXE;WINRTCOMPONENT_WINMD;PROJECTION_JSON;PROJECTION_DIR" "" ${ARGN})

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

    string(REPLACE "\\" "" WINDOWS_SDK_VERSION "$ENV{WindowsSDKVersion}") # Remove trailing slash

    # Determine the support package directory
    execute_process(
        COMMAND git.exe -C "${CMAKE_CURRENT_SOURCE_DIR}" rev-parse --path-format=absolute --show-toplevel
        OUTPUT_VARIABLE SPM_SUPPORT_PACKAGE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY)

    # Skip if the inputs have not changed
    file(SHA256 "${ARG_SWIFTWINRT_EXE}" SWIFTWINRT_EXE_HASH)
    file(SHA256 "${ARG_WINRTCOMPONENT_WINMD}" WINRTCOMPONENT_WINMD_HASH)
    file(SHA256 "${ARG_PROJECTION_JSON}" PROJECTION_JSON_HASH)
    set(CACHE_KEY
        "SwiftWinRT.exe: ${SWIFTWINRT_EXE_HASH}"
        "WinRTComponent.winmd: ${WINRTCOMPONENT_WINMD_HASH}"
        "Projection.json: ${PROJECTION_JSON_HASH}"
        "Projection directory: ${ARG_PROJECTION_DIR}"
        "Support package directory: ${SPM_SUPPORT_PACKAGE_DIR}"
        "Windows SDK version: ${WINDOWS_SDK_VERSION}")
    string(REPLACE ";" "\n" CACHE_KEY "${CACHE_KEY}")
    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/ProjectionCacheKey.txt")
        file(READ "${CMAKE_CURRENT_BINARY_DIR}/ProjectionCacheKey.txt" PREVIOUS_CACHE_KEY)
        if("${PREVIOUS_CACHE_KEY}" STREQUAL "${CACHE_KEY}")
            message(STATUS "Skipping projection generation because the inputs have not changed")
            return()
        endif()
    endif()

    # Delete the previous projection files
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${ARG_PROJECTION_DIR}"
        COMMAND_ERROR_IS_FATAL ANY)

    # Generate the projection
    cmake_path(CONVERT "${ARG_PROJECTION_JSON}" TO_NATIVE_PATH_LIST PROJECTION_JSON_NATIVE)
    cmake_path(CONVERT "${ARG_WINRTCOMPONENT_WINMD}" TO_NATIVE_PATH_LIST WINRTCOMPONENT_WINMD_NATIVE)
    cmake_path(CONVERT "${SPM_SUPPORT_PACKAGE_DIR}" TO_NATIVE_PATH_LIST SPM_SUPPORT_PACKAGE_DIR_NATIVE)
    cmake_path(CONVERT "${ARG_PROJECTION_DIR}" TO_NATIVE_PATH_LIST PROJECTION_DIR_NATIVE)

    if(DEFINED SWIFT_BUG_72724)
        if(${SWIFT_BUG_72724})
            set(SWIFT_BUG_72724_ARG "--swift-bug-72724=yes")
        else()
            set(SWIFT_BUG_72724_ARG "--swift-bug-72724=no")
        endif()
    endif()

    execute_process(
        COMMAND "${ARG_SWIFTWINRT_EXE}"
            --config "${PROJECTION_JSON_NATIVE}"
            --winsdk "${WINDOWS_SDK_VERSION}"
            --reference "${WINRTCOMPONENT_WINMD_NATIVE}"
            ${SWIFT_BUG_72724_ARG} # No quoting, may expand to nothing
            --spm
            --spm-support-package "${SPM_SUPPORT_PACKAGE_DIR_NATIVE}"
            --spm-library-prefix "Swift"
            --cmake
            --cmake-target-prefix "Swift"
            --out "${PROJECTION_DIR_NATIVE}"
            --out-manifest "${PROJECTION_DIR_NATIVE}\\WinRTComponent.manifest"
        COMMAND_ERROR_IS_FATAL ANY)

    # Save the cache key
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/ProjectionCacheKey.txt" "${CACHE_KEY}")
endfunction()

# Support running as a script
if(CMAKE_SCRIPT_MODE_FILE AND NOT CMAKE_PARENT_LIST_FILE)
    generate_projection(
        SWIFTWINRT_EXE "${SWIFTWINRT_EXE}"
        WINRTCOMPONENT_WINMD "${WINRTCOMPONENT_WINMD}"
        PROJECTION_JSON "${PROJECTION_JSON}"
        PROJECTION_DIR "${PROJECTION_DIR}")
endif()