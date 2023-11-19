#pragma once
#include "Passthrough.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Passthrough
    {
        Passthrough() = default;

        static winrt::WinRTComponent::IPassthrough Create();
        static winrt::WinRTComponent::IPassthrough CreateProxy(winrt::WinRTComponent::IPassthrough const& inner);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Passthrough : PassthroughT<Passthrough, implementation::Passthrough>
    {
    };
}
