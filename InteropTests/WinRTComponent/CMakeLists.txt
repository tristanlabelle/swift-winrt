cmake_minimum_required(VERSION 3.21.0)

project(WinRTComponent LANGUAGES CXX)

# Generate the WinMDs from the idl files
message(STATUS "Generating WinRTComponent.winmd...")
set(MIDLRT.EXE_PATH_NATIVE "$ENV{WindowsSdkVerBinPath}$ENV{VSCMD_ARG_HOST_ARCH}\\midlrt.exe")
cmake_path(CONVERT "$ENV{WindowsSdkDir}References\\$ENV{WindowsSDKVersion}" TO_CMAKE_PATH_LIST WINSDK_REFERENCES_DIR NORMALIZE)
set(FOUNDATIONCONTRACT_DIR "${WINSDK_REFERENCES_DIR}/Windows.Foundation.FoundationContract/4.0.0.0")
cmake_path(CONVERT "${FOUNDATIONCONTRACT_DIR}" TO_NATIVE_PATH_LIST METADATA_DIR_NATIVE)
cmake_path(CONVERT "${FOUNDATIONCONTRACT_DIR}/Windows.Foundation.FoundationContract.winmd" TO_NATIVE_PATH_LIST FOUNDATIONCONTRACT_WINMD_NATIVE)
cmake_path(CONVERT "${WINSDK_REFERENCES_DIR}/Windows.Foundation.UniversalApiContract/15.0.0.0/Windows.Foundation.UniversalApiContract.winmd" TO_NATIVE_PATH_LIST UNIVERSALAPICONTRACT_WINMD_NATIVE)
cmake_path(CONVERT "${CMAKE_CURRENT_BINARY_DIR}/WinRTComponent.winmd" TO_NATIVE_PATH_LIST GENERATED_WINMD_PATH_NATIVE)
cmake_path(CONVERT "${CMAKE_CURRENT_SOURCE_DIR}/All.idl" TO_NATIVE_PATH_LIST IDL_PATH_NATIVE)
execute_process(
    COMMAND "${MIDLRT.EXE_PATH_NATIVE}"
        /W1 /nologo /nomidl
        /metadata_dir "${METADATA_DIR_NATIVE}"
        /reference "${FOUNDATIONCONTRACT_WINMD_NATIVE}"
        /reference "${UNIVERSALAPICONTRACT_WINMD_NATIVE}"
        /winmd "${GENERATED_WINMD_PATH_NATIVE}"
        "${IDL_PATH_NATIVE}"
    COMMAND_ERROR_IS_FATAL ANY)

# Generate the C++/WinRT boilerplate
message(STATUS "Generating C++/WinRT boilerplate for WinRTComponent...")
set(CPPWINRT.EXE_PATH_NATIVE "$ENV{WindowsSdkVerBinPath}$ENV{VSCMD_ARG_HOST_ARCH}\\cppwinrt.exe")
string(REPLACE "\\" "" WINSDK_VERSION "$ENV{WindowsSDKVersion}")
cmake_path(CONVERT "${CMAKE_CURRENT_BINARY_DIR}/CppWinRT" TO_NATIVE_PATH_LIST CPPWINRT_OUTPUT_DIR_NATIVE)
execute_process(
    COMMAND "${CPPWINRT.EXE_PATH_NATIVE}"
        -input "${GENERATED_WINMD_PATH_NATIVE}"
        -reference "${WINSDK_VERSION}"
        -output "${CPPWINRT_OUTPUT_DIR_NATIVE}"
        COMMAND_ERROR_IS_FATAL ANY)