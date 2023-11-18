#include "pch.h"
#include "Structs.h"
#include "Structs.g.cpp"

namespace winrt::TestComponent::implementation
{
    winrt::TestComponent::Struct Structs::Make(int32_t a, hstring const& b, winrt::Windows::Foundation::IReference<int32_t> const& c, winrt::TestComponent::LeafStruct const& d)
    {
        return { a, b, c, d };
    }
    int32_t Structs::GetInt32(winrt::TestComponent::Struct const& value)
    {
        return value.Int32;
    }
    hstring Structs::GetString(winrt::TestComponent::Struct const& value)
    {
        return value.String;
    }
    winrt::Windows::Foundation::IReference<int32_t> Structs::GetReference(winrt::TestComponent::Struct const& value)
    {
        return value.Reference;
    }
    winrt::TestComponent::LeafStruct Structs::GetNested(winrt::TestComponent::Struct const& value)
    {
        return value.Nested;
    }
    void Structs::Output(int32_t a, hstring const& b, winrt::Windows::Foundation::IReference<int32_t> const& c, winrt::TestComponent::LeafStruct const& d, winrt::TestComponent::Struct& value)
    {
        value = { a, b, c, d };
    }
}
