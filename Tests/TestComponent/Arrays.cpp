#include "pch.h"
#include "Arrays.h"
#include "Arrays.g.cpp"

namespace winrt::TestComponent::implementation
{
    int32_t Arrays::GetLastInt32(array_view<int32_t const> value)
    {
        return value.back();
    }
    hstring Arrays::GetLastString(array_view<hstring const> value)
    {
        return value.back();
    }
    winrt::Windows::Foundation::IInspectable Arrays::GetLastObject(array_view<winrt::Windows::Foundation::IInspectable const> value)
    {
        return value.back();
    }
    winrt::TestComponent::MinimalEnum Arrays::GetLastEnum(array_view<winrt::TestComponent::MinimalEnum const> value)
    {
        return value.back();
    }
    winrt::TestComponent::MinimalStruct Arrays::GetLastStruct(array_view<winrt::TestComponent::MinimalStruct const> value)
    {
        return value.back();
    }
    winrt::TestComponent::IMinimalInterface Arrays::GetLastInterface(array_view<winrt::TestComponent::IMinimalInterface const> value)
    {
        return value.back();
    }
    winrt::TestComponent::MinimalClass Arrays::GetLastClass(array_view<winrt::TestComponent::MinimalClass const> value)
    {
        return value.back();
    }
    winrt::TestComponent::MinimalDelegate Arrays::GetLastDelegate(array_view<winrt::TestComponent::MinimalDelegate const> value)
    {
        return value.back();
    }
    com_array<int32_t> Arrays::MakeInt32(int32_t a, int32_t b)
    {
        return { a, b };
    }
    com_array<hstring> Arrays::MakeString(hstring const& a, hstring const& b)
    {
        return { a, b };
    }
    com_array<winrt::Windows::Foundation::IInspectable> Arrays::MakeObject(winrt::Windows::Foundation::IInspectable const& a, winrt::Windows::Foundation::IInspectable const& b)
    {
        return { a, b };
    }
    com_array<winrt::TestComponent::MinimalEnum> Arrays::MakeEnum(winrt::TestComponent::MinimalEnum const& a, winrt::TestComponent::MinimalEnum const& b)
    {
        return { a, b };
    }
    com_array<winrt::TestComponent::MinimalStruct> Arrays::MakeStruct(winrt::TestComponent::MinimalStruct const& a, winrt::TestComponent::MinimalStruct const& b)
    {
        return { a, b };
    }
    com_array<winrt::TestComponent::IMinimalInterface> Arrays::MakeInterface(winrt::TestComponent::IMinimalInterface const& a, winrt::TestComponent::IMinimalInterface const& b)
    {
        return { a, b };
    }
    com_array<winrt::TestComponent::MinimalClass> Arrays::MakeClass(winrt::TestComponent::MinimalClass const& a, winrt::TestComponent::MinimalClass const& b)
    {
        return { a, b };
    }
    com_array<winrt::TestComponent::MinimalDelegate> Arrays::MakeDelegate(winrt::TestComponent::MinimalDelegate const& a, winrt::TestComponent::MinimalDelegate const& b)
    {
        return { a, b };
    }
    void Arrays::OutputInt32(int32_t a, int32_t b, com_array<int32_t>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputString(hstring const& a, hstring const& b, com_array<hstring>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputObject(winrt::Windows::Foundation::IInspectable const& a, winrt::Windows::Foundation::IInspectable const& b, com_array<winrt::Windows::Foundation::IInspectable>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputEnum(winrt::TestComponent::MinimalEnum const& a, winrt::TestComponent::MinimalEnum const& b, com_array<winrt::TestComponent::MinimalEnum>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputStruct(winrt::TestComponent::MinimalStruct const& a, winrt::TestComponent::MinimalStruct const& b, com_array<winrt::TestComponent::MinimalStruct>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputInterface(winrt::TestComponent::IMinimalInterface const& a, winrt::TestComponent::IMinimalInterface const& b, com_array<winrt::TestComponent::IMinimalInterface>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputClass(winrt::TestComponent::MinimalClass const& a, winrt::TestComponent::MinimalClass const& b, com_array<winrt::TestComponent::MinimalClass>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputDelegate(winrt::TestComponent::MinimalDelegate const& a, winrt::TestComponent::MinimalDelegate const& b, com_array<winrt::TestComponent::MinimalDelegate>& array)
    {
        array = { a, b };
    }
    void Arrays::SwapFirstLastInt32(array_view<int32_t> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastString(array_view<hstring> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastObject(array_view<winrt::Windows::Foundation::IInspectable> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastEnum(array_view<winrt::TestComponent::MinimalEnum> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastStruct(array_view<winrt::TestComponent::MinimalStruct> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastInterface(array_view<winrt::TestComponent::IMinimalInterface> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastClass(array_view<winrt::TestComponent::MinimalClass> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastDelegate(array_view<winrt::TestComponent::MinimalDelegate> array)
    {
        std::swap(array.front(), array.back());
    }
}
