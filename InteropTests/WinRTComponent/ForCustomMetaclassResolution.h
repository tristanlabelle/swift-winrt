#pragma once
#include "ForCustomMetaclassResolution.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ForCustomMetaclassResolution
    {
        static void Method();
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ForCustomMetaclassResolution : ForCustomMetaclassResolutionT<ForCustomMetaclassResolution, implementation::ForCustomMetaclassResolution>
    {
    };
}
