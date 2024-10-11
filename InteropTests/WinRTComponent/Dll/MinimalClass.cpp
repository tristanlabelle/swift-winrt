#include "pch.h"
#include "MinimalClass.g.h"

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

#include "MinimalClass.g.cpp"