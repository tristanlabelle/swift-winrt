#pragma once
#include "Errors.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Errors
    {
        Errors() = default;

        static void FailWith(winrt::hresult const& hr, winrt::hstring const& message);
        static hstring NotImplementedProperty();
        static void NotImplementedProperty(hstring const& value);
        static winrt::hresult Catch(winrt::WinRTComponent::MinimalDelegate const& callee);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Errors : ErrorsT<Errors, implementation::Errors>
    {
    };
}
