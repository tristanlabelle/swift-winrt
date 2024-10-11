#include "pch.h"
#include "ForCustomActivationFactoryResolution.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ForCustomActivationFactoryResolution
    {
        static void Method() {}
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct ForCustomActivationFactoryResolution : ForCustomActivationFactoryResolutionT<ForCustomActivationFactoryResolution, implementation::ForCustomActivationFactoryResolution>
    {
    };
}

#include "ForCustomActivationFactoryResolution.g.cpp"