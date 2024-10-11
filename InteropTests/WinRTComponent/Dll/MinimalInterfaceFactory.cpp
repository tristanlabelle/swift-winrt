#include "pch.h"
#include "MinimalInterfaceFactory.g.h"

namespace
{
    struct MinimalInterfaceImplementation : winrt::implements<MinimalInterfaceImplementation, winrt::WinRTComponent::IMinimalInterface>
    {
        void Method() {}
    };
}

namespace winrt::WinRTComponent::implementation
{
    struct MinimalInterfaceFactory
    {
        static winrt::WinRTComponent::IMinimalInterface Create()
        {
            return winrt::make<MinimalInterfaceImplementation>();
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalInterfaceFactory : MinimalInterfaceFactoryT<MinimalInterfaceFactory, implementation::MinimalInterfaceFactory>
    {
    };
}

#include "MinimalInterfaceFactory.g.cpp"