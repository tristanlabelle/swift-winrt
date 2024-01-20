#pragma once
#include "MinimalUnsealedClass.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct MinimalUnsealedClass : MinimalUnsealedClassT<MinimalUnsealedClass>
    {
        MinimalUnsealedClass() = default;

        virtual bool IsDerived();

        static winrt::WinRTComponent::MinimalUnsealedClass Create();
        static winrt::WinRTComponent::MinimalUnsealedClass CreateDerived();
        static winrt::WinRTComponent::MinimalUnsealedClass Passthrough(winrt::WinRTComponent::MinimalUnsealedClass const& value);
        static bool GetIsDerived(winrt::WinRTComponent::MinimalUnsealedClass const& value);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalUnsealedClass : MinimalUnsealedClassT<MinimalUnsealedClass, implementation::MinimalUnsealedClass>
    {
    };
}
