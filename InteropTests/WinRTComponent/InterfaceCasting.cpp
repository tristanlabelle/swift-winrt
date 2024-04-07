#include "pch.h"
#include "InterfaceCasting.h"
#include "InterfaceCasting.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::IMinimalInterface InterfaceCasting::AsMinimalInterface(winrt::Windows::Foundation::IInspectable object) {
        return object.as<winrt::WinRTComponent::IMinimalInterface>();
    }
}
