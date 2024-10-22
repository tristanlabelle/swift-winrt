#include "pch.h"
#include "ShadowingConstructorsBase.g.h"
#include "ShadowingConstructorsDerived.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ShadowingConstructorsBase : ShadowingConstructorsBaseT<ShadowingConstructorsBase>
    {
        ShadowingConstructorsBase(int32_t) {}
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct ShadowingConstructorsBase : ShadowingConstructorsBaseT<ShadowingConstructorsBase, implementation::ShadowingConstructorsBase>
    {
    };
}

namespace winrt::WinRTComponent::implementation
{
    struct ShadowingConstructorsDerived : ShadowingConstructorsDerivedT<ShadowingConstructorsDerived, WinRTComponent::implementation::ShadowingConstructorsBase>
    {
        ShadowingConstructorsDerived(): ShadowingConstructorsBase(42) {}
        ShadowingConstructorsDerived(int32_t) {}
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct ShadowingConstructorsDerived : ShadowingConstructorsDerivedT<ShadowingConstructorsDerived, implementation::ShadowingConstructorsDerived>
    {
    };
}

#include "ShadowingConstructorsBase.g.cpp"
#include "ShadowingConstructorsDerived.g.cpp"