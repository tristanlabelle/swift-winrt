#pragma once
#include "Events.g.h"

namespace winrt::TestComponent::implementation
{
    struct Events
    {
        Events() = default;

        static winrt::TestComponent::IEvent Create();
        static winrt::TestComponent::IEventCounter CreateCounter(winrt::TestComponent::IEvent const& inner);
    };
}
namespace winrt::TestComponent::factory_implementation
{
    struct Events : EventsT<Events, implementation::Events>
    {
    };
}
