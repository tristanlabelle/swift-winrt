import UWP_Flat

// Compile-time tests that the UWP_Flat flat module
// exposes short names for types in that module.
fileprivate typealias MemoryBufferExists = MemoryBuffer // From UWP_WindowsFoundation
fileprivate typealias IBufferExists = IBuffer // From UWP_WindowsStorageStreams