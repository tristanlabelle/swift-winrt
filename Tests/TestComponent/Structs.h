#pragma once
#include "Structs.g.h"

namespace winrt::TestComponent::implementation
{
    struct Structs
    {
        Structs() = default;

        static winrt::TestComponent::Struct Make(int32_t a, hstring const& b, winrt::Windows::Foundation::IReference<int32_t> const& c, winrt::TestComponent::LeafStruct const& d);
        static int32_t GetInt32(winrt::TestComponent::Struct const& value);
        static hstring GetString(winrt::TestComponent::Struct const& value);
        static winrt::Windows::Foundation::IReference<int32_t> GetReference(winrt::TestComponent::Struct const& value);
        static winrt::TestComponent::LeafStruct GetNested(winrt::TestComponent::Struct const& value);
        static void Output(int32_t a, hstring const& b, winrt::Windows::Foundation::IReference<int32_t> const& c, winrt::TestComponent::LeafStruct const& d, winrt::TestComponent::Struct& value);
    };
}
namespace winrt::TestComponent::factory_implementation
{
    struct Structs : StructsT<Structs, implementation::Structs>
    {
    };
}
