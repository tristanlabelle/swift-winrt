#pragma once
#include "SwiftAttributes.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct SwiftAttributes
    {
        SwiftAttributes() = default;

        static void MainActor();
        static void AvailableFromSwift1();
        static int32_t AvailableFromSwift1WithDiscardableResult();
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct SwiftAttributes : SwiftAttributesT<SwiftAttributes, implementation::SwiftAttributes>
    {
    };
}
