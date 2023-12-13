#pragma once
#include "Structs.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Structs
    {
        Structs() = default;

        static winrt::WinRTComponent::Struct Make(int32_t a, hstring const& b, winrt::WinRTComponent::LeafStruct const& c);
        static int32_t GetInt32(winrt::WinRTComponent::Struct const& value);
        static hstring GetString(winrt::WinRTComponent::Struct const& value);
        static winrt::WinRTComponent::LeafStruct GetNested(winrt::WinRTComponent::Struct const& value);
        static void Output(int32_t a, hstring const& b, winrt::WinRTComponent::LeafStruct const& c, winrt::WinRTComponent::Struct& value);
        static winrt::WinRTComponent::Struct ReturnRefConstArgument(const winrt::WinRTComponent::Struct& value);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Structs : StructsT<Structs, implementation::Structs>
    {
    };
}
