#pragma once
#include "Passthrough.g.h"

namespace winrt::TestComponent::implementation
{
    struct Passthrough
    {
        Passthrough() = default;

        static winrt::TestComponent::IPassthrough Create();
        static winrt::TestComponent::IPassthrough CreateProxy(winrt::TestComponent::IPassthrough const& inner);
    };
}
namespace winrt::TestComponent::factory_implementation
{
    struct Passthrough : PassthroughT<Passthrough, implementation::Passthrough>
    {
    };
}
