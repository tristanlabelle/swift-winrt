cmake_minimum_required(VERSION 3.21.0)
project(WinRTComponentDll LANGUAGES CXX)

if(NOT DEFINED WINRTCOMPONENT_WINMD)
    message(FATAL_ERROR "WINRTCOMPONENT_WINMD must be defined")
endif()

# Generate the C++/WinRT boilerplate
message(STATUS "Generating C++/WinRT boilerplate for WinRTComponent...")
set(CPPWINRT_EXE_NATIVE "$ENV{WindowsSdkVerBinPath}$ENV{VSCMD_ARG_HOST_ARCH}\\cppwinrt.exe")
if(NOT EXISTS "${CPPWINRT_EXE_NATIVE}")
    message(FATAL_ERROR "Could not find cppwinrt.exe at ${CPPWINRT_EXE_NATIVE}")
endif()

cmake_path(CONVERT "${WINRTCOMPONENT_WINMD}" TO_NATIVE_PATH_LIST WINRTCOMPONENT_WINMD_NATIVE)
string(REPLACE "\\" "" WINSDK_VERSION "$ENV{WindowsSDKVersion}")
set(CPPWINRT_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/CppWinRT")
cmake_path(CONVERT "${CPPWINRT_GENERATED_DIR}" TO_NATIVE_PATH_LIST CPPWINRT_GENERATED_DIR_NATIVE)
file(REMOVE_RECURSE "${CPPWINRT_GENERATED_DIR}")
execute_process(
    COMMAND "${CPPWINRT_EXE_NATIVE}"
        -input "${WINRTCOMPONENT_WINMD_NATIVE}"
        -reference "${WINSDK_VERSION}"
        -component "${CPPWINRT_GENERATED_DIR_NATIVE}" -overwrite -optimize
        -output "${CPPWINRT_GENERATED_DIR_NATIVE}"
    COMMAND_ERROR_IS_FATAL ANY)

# Build WinRTComponent.dll
file(GLOB SOURCES "*.cpp")
add_library(WinRTComponent SHARED
    ${SOURCES}
    "${CPPWINRT_GENERATED_DIR}/module.g.cpp" # Other .g.cpp files are #included by our .cpp files
    WinRTComponent.def)
target_include_directories(WinRTComponent PRIVATE
    "${CMAKE_CURRENT_SOURCES_DIR}"
    "${CPPWINRT_GENERATED_DIR}")
target_precompile_headers(WinRTComponent PRIVATE pch.h)