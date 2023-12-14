#include "pch.h"
#include "Strings.h"
#include "Strings.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    hstring Strings::Roundtrip(hstring const& value) { return value; }
    char16_t Strings::RoundtripChar(char16_t value) { return value; }

    hstring Strings::FromChars(array_view<char16_t const> chars)
    {
        static_assert(sizeof(wchar_t) == sizeof(char16_t));
        return hstring(
            reinterpret_cast<const wchar_t*>(chars.data()),
            static_cast<hstring::size_type>(chars.size()));
    }

    com_array<char16_t> Strings::ToChars(hstring const& value)
    {
        static_assert(sizeof(wchar_t) == sizeof(char16_t));
        return com_array<char16_t>(
            reinterpret_cast<const char16_t*>(value.data()),
            reinterpret_cast<const char16_t*>(value.data()) + value.size());
    }
}
