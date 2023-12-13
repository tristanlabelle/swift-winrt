#include "pch.h"
#include "Structs.h"
#include "Structs.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::Struct Structs::Make(int32_t a, hstring const& b, winrt::WinRTComponent::LeafStruct const& c)
    {
        return { a, b, c };
    }
    int32_t Structs::GetInt32(winrt::WinRTComponent::Struct const& value)
    {
        return value.Int32;
    }
    hstring Structs::GetString(winrt::WinRTComponent::Struct const& value)
    {
        return value.String;
    }
    winrt::WinRTComponent::LeafStruct Structs::GetNested(winrt::WinRTComponent::Struct const& value)
    {
        return value.Nested;
    }
    void Structs::Output(int32_t a, hstring const& b, winrt::WinRTComponent::LeafStruct const& c, winrt::WinRTComponent::Struct& value)
    {
        value = { a, b, c };
    }
    winrt::WinRTComponent::Struct Structs::ReturnRefConstArgument(const winrt::WinRTComponent::Struct& value)
    {
        return value;
    }
}
