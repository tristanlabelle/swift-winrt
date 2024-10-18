# Determine if https://github.com/swiftlang/swift/issues/72724 is fixed with the current Swift toolchain.
message(STATUS "Checking compiler 'import typealias' correctness...")
execute_process(
    COMMAND "${CMAKE_COMMAND}"
        -S "${CMAKE_CURRENT_SOURCE_DIR}/Bug72724"
        -B "${CMAKE_CURRENT_BINARY_DIR}/Bug72724"
        -G "${CMAKE_GENERATOR}"
        -D "CMAKE_Swift_COMPILER=${CMAKE_Swift_COMPILER}"
    OUTPUT_QUIET
    COMMAND_ERROR_IS_FATAL ANY)
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_CURRENT_BINARY_DIR}/Bug72724"
    OUTPUT_QUIET
    RESULT_VARIABLE BUILD_RESULT)
if("${BUILD_RESULT}" STREQUAL "0")
    set(SWIFT_BUG_72724 "0" PARENT_SCOPE)
else()
    set(SWIFT_BUG_72724 "1" PARENT_SCOPE)
endif()