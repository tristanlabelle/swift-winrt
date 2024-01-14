#include "pch.h"
#include "MinimalTypes.h"
#include "MinimalClass.g.cpp"
#include "MinimalInterfaceFactory.g.cpp"

namespace
{
    struct MinimalInterfaceImplementation : winrt::implements<MinimalInterfaceImplementation, winrt::WinRTComponent::IMinimalInterface>
    {
        void Method() {}
    };
}

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::IMinimalInterface MinimalInterfaceFactory::Create()
    {
        return winrt::make<MinimalInterfaceImplementation>();
    }

    void MinimalClass::Method() {}
}
