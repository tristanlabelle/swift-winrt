#pragma once
#include "ReturnArgument.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ReturnArgument
    {
        ReturnArgument() = default;

        static winrt::WinRTComponent::IReturnArgument Create();
        static winrt::WinRTComponent::IReturnArgument CreateProxy(winrt::WinRTComponent::IReturnArgument const& inner);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ReturnArgument : ReturnArgumentT<ReturnArgument, implementation::ReturnArgument>
    {
    };
}
