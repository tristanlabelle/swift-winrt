# This directory can be built in two modes: standalone or as a subdirectory.
if("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    # Standalone mode. Only build the code generator.
    # We can't build InteropTests in this mode because it depends on SwiftWinRT.exe
    cmake_minimum_required(VERSION 3.21.0)

    project(SwiftWinRT LANGUAGES C Swift)

    add_subdirectory(Dependencies)
    add_subdirectory(Sources)
else()
    # Subdirectory mode. Build both the code generator and InteropTests.
    # Recursively invoke this build in standalone mode so that the code generator is built first,
    # and can be used when building InteropTests.
    message(STATUS "Configuring Generator as subproject...")
    execute_process(
        COMMAND ${CMAKE_COMMAND}
            -S "${CMAKE_CURRENT_SOURCE_DIR}"
            -B "${CMAKE_CURRENT_BINARY_DIR}"
            -G "${CMAKE_GENERATOR}"
            -D "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
            -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
            -D "CMAKE_Swift_COMPILER=${CMAKE_Swift_COMPILER}"
        COMMAND_ERROR_IS_FATAL ANY)

    message(STATUS "Building Generator as subproject...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} --build "${CMAKE_CURRENT_BINARY_DIR}"
        COMMAND_ERROR_IS_FATAL ANY)

    # Now build InteropTests, which depends on SWIFTWINRT_EXE
    set(SWIFTWINRT_EXE "${CMAKE_CURRENT_BINARY_DIR}/Sources/SwiftWinRT/SwiftWinRT.exe")
    add_subdirectory(InteropTests)
endif()
