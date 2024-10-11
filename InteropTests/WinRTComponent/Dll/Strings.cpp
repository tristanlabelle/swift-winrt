#include "pch.h"
#include "Strings.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Strings
    {
        static hstring Roundtrip(hstring const& value) { return value; }
        static char16_t RoundtripChar(char16_t value) { return value; }

        static hstring FromChars(array_view<char16_t const> chars)
        {
            static_assert(sizeof(wchar_t) == sizeof(char16_t));
            return hstring(
                reinterpret_cast<const wchar_t*>(chars.data()),
                static_cast<hstring::size_type>(chars.size()));
        }

        static com_array<char16_t> ToChars(hstring const& value)
        {
            static_assert(sizeof(wchar_t) == sizeof(char16_t));
            return com_array<char16_t>(
                reinterpret_cast<const char16_t*>(value.data()),
                reinterpret_cast<const char16_t*>(value.data()) + value.size());
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Strings : StringsT<Strings, implementation::Strings>
    {
    };
}

#include "Strings.g.cpp"