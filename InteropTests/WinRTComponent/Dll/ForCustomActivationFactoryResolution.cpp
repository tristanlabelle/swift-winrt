#include "pch.h"
#include "ForCustomActivationFactoryResolution.g.h"
#include "ForCustomActivationFactoryResolution.g.cpp"

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
