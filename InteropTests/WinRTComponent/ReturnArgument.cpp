#include "pch.h"
#include "ReturnArgument.h"
#include "ReturnArgument.g.cpp"

namespace
{
    class Implementation : public winrt::implements<Implementation, winrt::WinRTComponent::IReturnArgument>
    {
    public:
        int32_t Int32(int32_t value) { return value; }
        winrt::hstring String(winrt::hstring const& value) { return value; }
        winrt::Windows::Foundation::IInspectable Object(winrt::Windows::Foundation::IInspectable const& value) { return value; }
        winrt::WinRTComponent::MinimalEnum Enum(winrt::WinRTComponent::MinimalEnum const& value) { return value; }
        winrt::WinRTComponent::MinimalStruct Struct(winrt::WinRTComponent::MinimalStruct const& value) { return value; }
        winrt::WinRTComponent::IMinimalInterface Interface(winrt::WinRTComponent::IMinimalInterface const& value) { return value; }
        winrt::WinRTComponent::MinimalClass Class(winrt::WinRTComponent::MinimalClass const& value) { return value; }
        winrt::WinRTComponent::MinimalDelegate Delegate(winrt::WinRTComponent::MinimalDelegate const& value) { return value; }
        winrt::com_array<winrt::hstring> Array(winrt::array_view<winrt::hstring const> value) { return { value.begin(), value.end() }; }
    };

    class Proxy : public winrt::implements<Proxy, winrt::WinRTComponent::IReturnArgument>
    {
    private:
        winrt::WinRTComponent::IReturnArgument inner;

    public:
        Proxy(winrt::WinRTComponent::IReturnArgument inner) : inner(inner) {}

        int32_t Int32(int32_t value) { return inner.Int32(value); }
        winrt::hstring String(winrt::hstring const& value) { return inner.String(value); }
        winrt::Windows::Foundation::IInspectable Object(winrt::Windows::Foundation::IInspectable const& value) { return inner.Object(value); }
        winrt::WinRTComponent::MinimalEnum Enum(winrt::WinRTComponent::MinimalEnum const& value) { return inner.Enum(value); }
        winrt::WinRTComponent::MinimalStruct Struct(winrt::WinRTComponent::MinimalStruct const& value) { return inner.Struct(value); }
        winrt::WinRTComponent::IMinimalInterface Interface(winrt::WinRTComponent::IMinimalInterface const& value) { return inner.Interface(value); }
        winrt::WinRTComponent::MinimalClass Class(winrt::WinRTComponent::MinimalClass const& value) { return inner.Class(value); }
        winrt::WinRTComponent::MinimalDelegate Delegate(winrt::WinRTComponent::MinimalDelegate const& value) { return inner.Delegate(value); }
        winrt::com_array<winrt::hstring> Array(winrt::array_view<winrt::hstring const> value) { return inner.Array(value); }
    };
}

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::IReturnArgument ReturnArgument::Create()
    {
        return winrt::make<Implementation>();
    }
    winrt::WinRTComponent::IReturnArgument ReturnArgument::CreateProxy(winrt::WinRTComponent::IReturnArgument const& inner)
    {
        return winrt::make<Proxy>(inner);
    }
}
