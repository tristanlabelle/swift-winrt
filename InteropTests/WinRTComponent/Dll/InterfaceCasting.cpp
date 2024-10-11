#include "pch.h"
#include "InterfaceCasting.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct InterfaceCasting
    {
        static winrt::WinRTComponent::IMinimalInterface AsMinimalInterface(winrt::Windows::Foundation::IInspectable object)
        {
            return object.as<winrt::WinRTComponent::IMinimalInterface>();
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct InterfaceCasting : InterfaceCastingT<InterfaceCasting, implementation::InterfaceCasting>
    {
    };
}

#include "InterfaceCasting.g.cpp"