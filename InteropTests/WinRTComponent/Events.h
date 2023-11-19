#pragma once
#include "Events.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Events
    {
        Events() = default;

        static winrt::WinRTComponent::IEvent Create();
        static winrt::WinRTComponent::IEventCounter CreateCounter(winrt::WinRTComponent::IEvent const& inner);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Events : EventsT<Events, implementation::Events>
    {
    };
}
