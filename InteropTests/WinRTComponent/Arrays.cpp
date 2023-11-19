#include "pch.h"
#include "Arrays.h"
#include "Arrays.g.cpp"

namespace winrt::WinRTComponent::implementation
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
    winrt::WinRTComponent::MinimalEnum Arrays::GetLastEnum(array_view<winrt::WinRTComponent::MinimalEnum const> value)
    {
        return value.back();
    }
    winrt::WinRTComponent::MinimalStruct Arrays::GetLastStruct(array_view<winrt::WinRTComponent::MinimalStruct const> value)
    {
        return value.back();
    }
    winrt::WinRTComponent::IMinimalInterface Arrays::GetLastInterface(array_view<winrt::WinRTComponent::IMinimalInterface const> value)
    {
        return value.back();
    }
    winrt::WinRTComponent::MinimalClass Arrays::GetLastClass(array_view<winrt::WinRTComponent::MinimalClass const> value)
    {
        return value.back();
    }
    winrt::WinRTComponent::MinimalDelegate Arrays::GetLastDelegate(array_view<winrt::WinRTComponent::MinimalDelegate const> value)
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
    com_array<winrt::WinRTComponent::MinimalEnum> Arrays::MakeEnum(winrt::WinRTComponent::MinimalEnum const& a, winrt::WinRTComponent::MinimalEnum const& b)
    {
        return { a, b };
    }
    com_array<winrt::WinRTComponent::MinimalStruct> Arrays::MakeStruct(winrt::WinRTComponent::MinimalStruct const& a, winrt::WinRTComponent::MinimalStruct const& b)
    {
        return { a, b };
    }
    com_array<winrt::WinRTComponent::IMinimalInterface> Arrays::MakeInterface(winrt::WinRTComponent::IMinimalInterface const& a, winrt::WinRTComponent::IMinimalInterface const& b)
    {
        return { a, b };
    }
    com_array<winrt::WinRTComponent::MinimalClass> Arrays::MakeClass(winrt::WinRTComponent::MinimalClass const& a, winrt::WinRTComponent::MinimalClass const& b)
    {
        return { a, b };
    }
    com_array<winrt::WinRTComponent::MinimalDelegate> Arrays::MakeDelegate(winrt::WinRTComponent::MinimalDelegate const& a, winrt::WinRTComponent::MinimalDelegate const& b)
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
    void Arrays::OutputEnum(winrt::WinRTComponent::MinimalEnum const& a, winrt::WinRTComponent::MinimalEnum const& b, com_array<winrt::WinRTComponent::MinimalEnum>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputStruct(winrt::WinRTComponent::MinimalStruct const& a, winrt::WinRTComponent::MinimalStruct const& b, com_array<winrt::WinRTComponent::MinimalStruct>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputInterface(winrt::WinRTComponent::IMinimalInterface const& a, winrt::WinRTComponent::IMinimalInterface const& b, com_array<winrt::WinRTComponent::IMinimalInterface>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputClass(winrt::WinRTComponent::MinimalClass const& a, winrt::WinRTComponent::MinimalClass const& b, com_array<winrt::WinRTComponent::MinimalClass>& array)
    {
        array = { a, b };
    }
    void Arrays::OutputDelegate(winrt::WinRTComponent::MinimalDelegate const& a, winrt::WinRTComponent::MinimalDelegate const& b, com_array<winrt::WinRTComponent::MinimalDelegate>& array)
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
    void Arrays::SwapFirstLastEnum(array_view<winrt::WinRTComponent::MinimalEnum> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastStruct(array_view<winrt::WinRTComponent::MinimalStruct> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastInterface(array_view<winrt::WinRTComponent::IMinimalInterface> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastClass(array_view<winrt::WinRTComponent::MinimalClass> array)
    {
        std::swap(array.front(), array.back());
    }
    void Arrays::SwapFirstLastDelegate(array_view<winrt::WinRTComponent::MinimalDelegate> array)
    {
        std::swap(array.front(), array.back());
    }
}
