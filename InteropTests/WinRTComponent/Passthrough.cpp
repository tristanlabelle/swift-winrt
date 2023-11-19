#include "pch.h"
#include "Passthrough.h"
#include "Passthrough.g.cpp"

namespace
{
    class Implementation : public winrt::implements<Implementation, winrt::WinRTComponent::IPassthrough>
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
        winrt::Windows::Foundation::IReference<int32_t> Reference(winrt::Windows::Foundation::IReference<int32_t> const& value) { return value; }
    };

    class Proxy : public winrt::implements<Proxy, winrt::WinRTComponent::IPassthrough>
    {
    private:
        winrt::WinRTComponent::IPassthrough inner;

    public:
        Proxy(winrt::WinRTComponent::IPassthrough inner) : inner(inner) {}

        int32_t Int32(int32_t value) { return inner.Int32(value); }
        winrt::hstring String(winrt::hstring const& value) { return inner.String(value); }
        winrt::Windows::Foundation::IInspectable Object(winrt::Windows::Foundation::IInspectable const& value) { return inner.Object(value); }
        winrt::WinRTComponent::MinimalEnum Enum(winrt::WinRTComponent::MinimalEnum const& value) { return inner.Enum(value); }
        winrt::WinRTComponent::MinimalStruct Struct(winrt::WinRTComponent::MinimalStruct const& value) { return inner.Struct(value); }
        winrt::WinRTComponent::IMinimalInterface Interface(winrt::WinRTComponent::IMinimalInterface const& value) { return inner.Interface(value); }
        winrt::WinRTComponent::MinimalClass Class(winrt::WinRTComponent::MinimalClass const& value) { return inner.Class(value); }
        winrt::WinRTComponent::MinimalDelegate Delegate(winrt::WinRTComponent::MinimalDelegate const& value) { return inner.Delegate(value); }
        winrt::Windows::Foundation::IReference<int32_t> Reference(winrt::Windows::Foundation::IReference<int32_t> const& value) { return inner.Reference(value); }
    };
}

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::IPassthrough Passthrough::Create()
    {
        return winrt::make<Implementation>();
    }
    winrt::WinRTComponent::IPassthrough Passthrough::CreateProxy(winrt::WinRTComponent::IPassthrough const& inner)
    {
        return winrt::make<Proxy>(inner);
    }
}
