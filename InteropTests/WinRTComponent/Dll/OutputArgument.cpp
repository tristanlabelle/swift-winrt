#include "pch.h"
#include "OutputArgument.h"
#include "OutputArgument.g.cpp"

namespace
{
    class Implementation : public winrt::implements<Implementation, winrt::WinRTComponent::IOutputArgument>
    {
    public:
        void Int32(int32_t value, int32_t& result) { result = value; }
        void String(winrt::hstring const& value, winrt::hstring& result) { result = value; }
        void Object(winrt::Windows::Foundation::IInspectable const& value, winrt::Windows::Foundation::IInspectable& result) { result = value; }
        void Enum(winrt::WinRTComponent::MinimalEnum const& value, winrt::WinRTComponent::MinimalEnum& result) { result = value; }
        void Struct(winrt::WinRTComponent::MinimalStruct const& value, winrt::WinRTComponent::MinimalStruct& result) { result = value; }
        void Interface(winrt::WinRTComponent::IMinimalInterface const& value, winrt::WinRTComponent::IMinimalInterface& result) { result = value; }
        void Class(winrt::WinRTComponent::MinimalClass const& value, winrt::WinRTComponent::MinimalClass& result) { result = value; }
        void Delegate(winrt::WinRTComponent::MinimalDelegate const& value, winrt::WinRTComponent::MinimalDelegate& result) { result = value; }
        void Array(winrt::array_view<winrt::hstring const> value, winrt::com_array<winrt::hstring>& result) { result = { value.begin(), value.end() }; }
        void Reference(winrt::Windows::Foundation::IReference<int32_t> const& value, winrt::Windows::Foundation::IReference<int32_t>& result) { result = value; }
    };

    class Proxy : public winrt::implements<Proxy, winrt::WinRTComponent::IOutputArgument>
    {
    private:
        winrt::WinRTComponent::IOutputArgument inner;

    public:
        Proxy(winrt::WinRTComponent::IOutputArgument inner) : inner(inner) {}

        void Int32(int32_t value, int32_t& result) { inner.Int32(value, result); }
        void String(winrt::hstring const& value, winrt::hstring& result) { inner.String(value, result); }
        void Object(winrt::Windows::Foundation::IInspectable const& value, winrt::Windows::Foundation::IInspectable& result) { inner.Object(value, result); }
        void Enum(winrt::WinRTComponent::MinimalEnum const& value, winrt::WinRTComponent::MinimalEnum& result) { inner.Enum(value, result); }
        void Struct(winrt::WinRTComponent::MinimalStruct const& value, winrt::WinRTComponent::MinimalStruct& result) { inner.Struct(value, result); }
        void Interface(winrt::WinRTComponent::IMinimalInterface const& value, winrt::WinRTComponent::IMinimalInterface& result) { inner.Interface(value, result); }
        void Class(winrt::WinRTComponent::MinimalClass const& value, winrt::WinRTComponent::MinimalClass& result) { inner.Class(value, result); }
        void Delegate(winrt::WinRTComponent::MinimalDelegate const& value, winrt::WinRTComponent::MinimalDelegate& result) { inner.Delegate(value, result); }
        void Array(winrt::array_view<winrt::hstring const> value, winrt::com_array<winrt::hstring>& result) { inner.Array(value, result); }
        void Reference(winrt::Windows::Foundation::IReference<int32_t> const& value, winrt::Windows::Foundation::IReference<int32_t>& result) { inner.Reference(value, result); }
    };
}

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::IOutputArgument OutputArgument::Create()
    {
        return winrt::make<Implementation>();
    }
    winrt::WinRTComponent::IOutputArgument OutputArgument::CreateProxy(winrt::WinRTComponent::IOutputArgument const& inner)
    {
        return winrt::make<Proxy>(inner);
    }
}
