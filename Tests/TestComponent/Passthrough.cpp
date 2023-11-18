#include "pch.h"
#include "Passthrough.h"
#include "Passthrough.g.cpp"

namespace
{
    class Implementation : public winrt::implements<Implementation, winrt::TestComponent::IPassthrough>
    {
    public:
        int32_t Int32(int32_t value) { return value; }
        winrt::hstring String(winrt::hstring const& value) { return value; }
        winrt::Windows::Foundation::IInspectable Object(winrt::Windows::Foundation::IInspectable const& value) { return value; }
        winrt::TestComponent::MinimalEnum Enum(winrt::TestComponent::MinimalEnum const& value) { return value; }
        winrt::TestComponent::MinimalStruct Struct(winrt::TestComponent::MinimalStruct const& value) { return value; }
        winrt::TestComponent::IMinimalInterface Interface(winrt::TestComponent::IMinimalInterface const& value) { return value; }
        winrt::TestComponent::MinimalClass Class(winrt::TestComponent::MinimalClass const& value) { return value; }
        winrt::TestComponent::MinimalDelegate Delegate(winrt::TestComponent::MinimalDelegate const& value) { return value; }
        winrt::Windows::Foundation::IReference<int32_t> Reference(winrt::Windows::Foundation::IReference<int32_t> const& value) { return value; }
    };

    class Proxy : public winrt::implements<Proxy, winrt::TestComponent::IPassthrough>
    {
    private:
        winrt::TestComponent::IPassthrough inner;

    public:
        Proxy(winrt::TestComponent::IPassthrough inner) : inner(inner) {}

        int32_t Int32(int32_t value) { return inner.Int32(value); }
        winrt::hstring String(winrt::hstring const& value) { return inner.String(value); }
        winrt::Windows::Foundation::IInspectable Object(winrt::Windows::Foundation::IInspectable const& value) { return inner.Object(value); }
        winrt::TestComponent::MinimalEnum Enum(winrt::TestComponent::MinimalEnum const& value) { return inner.Enum(value); }
        winrt::TestComponent::MinimalStruct Struct(winrt::TestComponent::MinimalStruct const& value) { return inner.Struct(value); }
        winrt::TestComponent::IMinimalInterface Interface(winrt::TestComponent::IMinimalInterface const& value) { return inner.Interface(value); }
        winrt::TestComponent::MinimalClass Class(winrt::TestComponent::MinimalClass const& value) { return inner.Class(value); }
        winrt::TestComponent::MinimalDelegate Delegate(winrt::TestComponent::MinimalDelegate const& value) { return inner.Delegate(value); }
        winrt::Windows::Foundation::IReference<int32_t> Reference(winrt::Windows::Foundation::IReference<int32_t> const& value) { return inner.Reference(value); }
    };
}

namespace winrt::TestComponent::implementation
{
    winrt::TestComponent::IPassthrough Passthrough::Create()
    {
        return winrt::make<Implementation>();
    }
    winrt::TestComponent::IPassthrough Passthrough::CreateProxy(winrt::TestComponent::IPassthrough const& inner)
    {
        return winrt::make<Proxy>(inner);
    }
}
