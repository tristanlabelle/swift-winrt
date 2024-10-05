#pragma once
#include "MinimalInterfaceFactory.g.h"
#include "MinimalClass.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct MinimalInterfaceFactory
    {
        MinimalInterfaceFactory() = default;

        static winrt::WinRTComponent::IMinimalInterface Create();
    };

    struct MinimalClass : MinimalClassT<MinimalClass>
    {
        MinimalClass() = default;

        void Method();
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalInterfaceFactory : MinimalInterfaceFactoryT<MinimalInterfaceFactory, implementation::MinimalInterfaceFactory>
    {
    };

    struct MinimalClass : MinimalClassT<MinimalClass, implementation::MinimalClass>
    {
    };
}
