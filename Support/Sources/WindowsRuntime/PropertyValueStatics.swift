import CWinRTCore

fileprivate var _propertyValueStatics: UnsafeMutablePointer<SWRT_IPropertyValueStatics>? = nil

internal func getPropertyValueStaticsNoRef() throws -> UnsafeMutablePointer<SWRT_IPropertyValueStatics> {
    try lazyInitActivationFactoryPointer(
        &_propertyValueStatics,
        activatableId: "Windows.Foundation.PropertyValue",
        id: COMInterfaceID(0x629BDBC8, 0xD932, 0x4FF4, 0x96B9, 0x8D96C5C1E858))
}