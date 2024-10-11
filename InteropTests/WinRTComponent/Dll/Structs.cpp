#include "pch.h"
#include "Structs.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Structs
    {
        static winrt::WinRTComponent::Struct Make(int32_t int32, hstring const& string, winrt::Windows::Foundation::IReference<int32_t> const& reference, winrt::WinRTComponent::LeafStruct const& nested)
        {
            return { int32, string, reference, nested };
        }

        static int32_t GetInt32(winrt::WinRTComponent::Struct const& value) { return value.Int32; }
        static hstring GetString(winrt::WinRTComponent::Struct const& value) { return value.String; }
        static winrt::Windows::Foundation::IReference<int32_t> GetReference(winrt::WinRTComponent::Struct const& value) { return value.Reference; }
        static winrt::WinRTComponent::LeafStruct GetNested(winrt::WinRTComponent::Struct const& value) { return value.Nested; }

        static void Output(int32_t int32, hstring const& string, winrt::Windows::Foundation::IReference<int32_t> const& reference, winrt::WinRTComponent::LeafStruct const& nested, winrt::WinRTComponent::Struct& value)
        {
            value = { int32, string, reference, nested };
        }

        static winrt::WinRTComponent::Struct ReturnRefConstArgument(const winrt::WinRTComponent::Struct& value)
        {
            return value;
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Structs : StructsT<Structs, implementation::Structs>
    {
    };
}

#include "Structs.g.cpp"