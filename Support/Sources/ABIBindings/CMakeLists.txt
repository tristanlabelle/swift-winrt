file(GLOB_RECURSE SOURCES *.swift)
add_library(ABIBindings STATIC ${SOURCES})