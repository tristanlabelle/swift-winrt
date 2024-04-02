#pragma once
#include "MinimalBaseClass.g.h"
#include "MinimalDerivedClass.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct MinimalBaseClass : MinimalBaseClassT<MinimalBaseClass>
    {
        MinimalBaseClass() = default;

        virtual winrt::hstring TypeName();

        static winrt::WinRTComponent::MinimalBaseClass CreateBase();
        static winrt::WinRTComponent::MinimalBaseClass CreatePrivate();
        static winrt::WinRTComponent::MinimalBaseClass Passthrough(winrt::WinRTComponent::MinimalBaseClass const& value);
        static winrt::hstring GetTypeName(winrt::WinRTComponent::MinimalBaseClass const& value);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalBaseClass : MinimalBaseClassT<MinimalBaseClass, implementation::MinimalBaseClass>
    {
    };
}

namespace winrt::WinRTComponent::implementation
{
    struct MinimalDerivedClass : MinimalDerivedClassT<MinimalDerivedClass, WinRTComponent::implementation::MinimalBaseClass>
    {
        MinimalDerivedClass() = default;
        
        virtual winrt::hstring TypeName() override;

        static winrt::WinRTComponent::MinimalDerivedClass CreateDerived();
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalDerivedClass : MinimalDerivedClassT<MinimalDerivedClass, implementation::MinimalDerivedClass>
    {
    };
}
