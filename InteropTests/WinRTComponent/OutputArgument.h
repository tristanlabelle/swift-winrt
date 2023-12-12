#pragma once
#include "OutputArgument.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct OutputArgument
    {
        OutputArgument() = default;

        static winrt::WinRTComponent::IOutputArgument Create();
        static winrt::WinRTComponent::IOutputArgument CreateProxy(winrt::WinRTComponent::IOutputArgument const& inner);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct OutputArgument : OutputArgumentT<OutputArgument, implementation::OutputArgument>
    {
    };
}
