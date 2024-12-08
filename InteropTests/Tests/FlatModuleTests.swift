import UWP_Flat

// Compile-time tests that the UWP_Flat flat module
// exposes short names for types in that module.
typealias MemoryBufferExists = MemoryBuffer // From UWP_WindowsFoundation
typealias IBufferExists = IBuffer // From UWP_WindowsStorageStreams