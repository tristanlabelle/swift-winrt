#include "pch.h"
#include "MinimalClass.g.h"
#include "MinimalInterfaceFactory.g.h"
#include "MinimalClass.g.cpp"
#include "MinimalInterfaceFactory.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    struct MinimalClass : MinimalClassT<MinimalClass>
    {
        void Method() {}
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalClass : MinimalClassT<MinimalClass, implementation::MinimalClass>
    {
    };
}
