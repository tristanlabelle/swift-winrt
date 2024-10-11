#include "pch.h"
#include "SwiftAttributes.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct SwiftAttributes
    {
        static void MainActor() {}
        static void AvailableFromSwift1() {}
        static int32_t AvailableFromSwift1WithDiscardableResult() { return 42; }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct SwiftAttributes : SwiftAttributesT<SwiftAttributes, implementation::SwiftAttributes>
    {
    };
}

#include "SwiftAttributes.g.cpp"