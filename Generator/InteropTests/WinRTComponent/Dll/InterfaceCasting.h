#pragma once
#include "InterfaceCasting.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct InterfaceCasting
    {
        static winrt::WinRTComponent::IMinimalInterface AsMinimalInterface(winrt::Windows::Foundation::IInspectable object);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct InterfaceCasting : InterfaceCastingT<InterfaceCasting, implementation::InterfaceCasting>
    {
    };
}
