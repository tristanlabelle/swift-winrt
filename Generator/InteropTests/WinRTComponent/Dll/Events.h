#pragma once
#include "Events.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Events
    {
        Events() = default;

        static winrt::WinRTComponent::IEventSource CreateSource();
        static winrt::WinRTComponent::IEventCounter CreateCounter(winrt::WinRTComponent::IEventSource const& source);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Events : EventsT<Events, implementation::Events>
    {
    };
}
