#include "pch.h"
#include "Structs.h"
#include "Structs.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::Struct Structs::Make(int32_t int32, hstring const& string, winrt::Windows::Foundation::IReference<int32_t> const& reference, winrt::WinRTComponent::LeafStruct const& nested)
    {
        return { int32, string, reference, nested };
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
    void Structs::Output(int32_t int32, hstring const& string, winrt::Windows::Foundation::IReference<int32_t> const& reference, winrt::WinRTComponent::LeafStruct const& nested, winrt::WinRTComponent::Struct& value)
    {
        value = { int32, string, reference, nested };
    }
    winrt::WinRTComponent::Struct Structs::ReturnRefConstArgument(const winrt::WinRTComponent::Struct& value)
    {
        return value;
    }
}
