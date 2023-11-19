#include "pch.h"
#include "Structs.h"
#include "Structs.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::Struct Structs::Make(int32_t a, hstring const& b, winrt::Windows::Foundation::IReference<int32_t> const& c, winrt::WinRTComponent::LeafStruct const& d)
    {
        return { a, b, c, d };
    }
    int32_t Structs::GetInt32(winrt::WinRTComponent::Struct const& value)
    {
        return value.Int32;
    }
    hstring Structs::GetString(winrt::WinRTComponent::Struct const& value)
    {
        return value.String;
    }
    winrt::Windows::Foundation::IReference<int32_t> Structs::GetReference(winrt::WinRTComponent::Struct const& value)
    {
        return value.Reference;
    }
    winrt::WinRTComponent::LeafStruct Structs::GetNested(winrt::WinRTComponent::Struct const& value)
    {
        return value.Nested;
    }
    void Structs::Output(int32_t a, hstring const& b, winrt::Windows::Foundation::IReference<int32_t> const& c, winrt::WinRTComponent::LeafStruct const& d, winrt::WinRTComponent::Struct& value)
    {
        value = { a, b, c, d };
    }
}
