#pragma once
#include "Strings.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Strings
    {
        Strings() = default;

        static hstring Roundtrip(hstring const& value);
        static char16_t RoundtripChar(char16_t value);
        static hstring FromChars(array_view<char16_t const> chars);
        static com_array<char16_t> ToChars(hstring const& value);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Strings : StringsT<Strings, implementation::Strings>
    {
    };
}
