cmake_minimum_required(VERSION 3.21.0)

project(InteropTests LANGUAGES C Swift)

if (NOT DEFINED SWIFT_WINRT_EXE)
    message(FATAL_ERROR "SWIFT_WINRT_EXE must be defined")
endif()

# Build WinRTComponent.winmd/dll
make_path(NATIVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/InteropTests/WinRTComponent/Build.ps1" SCRIPT_PATH)
execute_process(
    COMMAND powershell.exe "${SCRIPT_PATH}"
        -BinaryDirBase "${CMAKE_CURRENT_BINARY_DIR}\\WinRTComponent"
    OUTPUT_VARIABLE WINRTCOMPONENT_BINARY_DIR)

# Generate Swift projection
make_path(NATIVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/GenerateProjection.ps1" SCRIPT_PATH)
execute_process(
    COMMAND powershell.exe "${SCRIPT_PATH}"
        -SwiftWinRT "${SWIFT_WINRT_EXE}"
        -WinMD "${WINRTCOMPONENT_BINARY_DIR}\\WinRTComponent.winmd"
        -OutputDir "${CMAKE_CURRENT_BINARY_DIR}\\Generated\\Sources")

# Build the Swift projection
add_subdirectory(
    ${CMAKE_CURRENT_BINARY_DIR}/Generated/Sources
    ${CMAKE_CURRENT_BINARY_DIR}/Generated/Build)