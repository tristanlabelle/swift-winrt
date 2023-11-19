#pragma once
#include "Arrays.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Arrays
    {
        Arrays() = default;

        static int32_t GetLastInt32(array_view<int32_t const> value);
        static hstring GetLastString(array_view<hstring const> value);
        static winrt::Windows::Foundation::IInspectable GetLastObject(array_view<winrt::Windows::Foundation::IInspectable const> value);
        static winrt::WinRTComponent::MinimalEnum GetLastEnum(array_view<winrt::WinRTComponent::MinimalEnum const> value);
        static winrt::WinRTComponent::MinimalStruct GetLastStruct(array_view<winrt::WinRTComponent::MinimalStruct const> value);
        static winrt::WinRTComponent::IMinimalInterface GetLastInterface(array_view<winrt::WinRTComponent::IMinimalInterface const> value);
        static winrt::WinRTComponent::MinimalClass GetLastClass(array_view<winrt::WinRTComponent::MinimalClass const> value);
        static winrt::WinRTComponent::MinimalDelegate GetLastDelegate(array_view<winrt::WinRTComponent::MinimalDelegate const> value);
        static com_array<int32_t> MakeInt32(int32_t a, int32_t b);
        static com_array<hstring> MakeString(hstring const& a, hstring const& b);
        static com_array<winrt::Windows::Foundation::IInspectable> MakeObject(winrt::Windows::Foundation::IInspectable const& a, winrt::Windows::Foundation::IInspectable const& b);
        static com_array<winrt::WinRTComponent::MinimalEnum> MakeEnum(winrt::WinRTComponent::MinimalEnum const& a, winrt::WinRTComponent::MinimalEnum const& b);
        static com_array<winrt::WinRTComponent::MinimalStruct> MakeStruct(winrt::WinRTComponent::MinimalStruct const& a, winrt::WinRTComponent::MinimalStruct const& b);
        static com_array<winrt::WinRTComponent::IMinimalInterface> MakeInterface(winrt::WinRTComponent::IMinimalInterface const& a, winrt::WinRTComponent::IMinimalInterface const& b);
        static com_array<winrt::WinRTComponent::MinimalClass> MakeClass(winrt::WinRTComponent::MinimalClass const& a, winrt::WinRTComponent::MinimalClass const& b);
        static com_array<winrt::WinRTComponent::MinimalDelegate> MakeDelegate(winrt::WinRTComponent::MinimalDelegate const& a, winrt::WinRTComponent::MinimalDelegate const& b);
        static void OutputInt32(int32_t a, int32_t b, com_array<int32_t>& array);
        static void OutputString(hstring const& a, hstring const& b, com_array<hstring>& array);
        static void OutputObject(winrt::Windows::Foundation::IInspectable const& a, winrt::Windows::Foundation::IInspectable const& b, com_array<winrt::Windows::Foundation::IInspectable>& array);
        static void OutputEnum(winrt::WinRTComponent::MinimalEnum const& a, winrt::WinRTComponent::MinimalEnum const& b, com_array<winrt::WinRTComponent::MinimalEnum>& array);
        static void OutputStruct(winrt::WinRTComponent::MinimalStruct const& a, winrt::WinRTComponent::MinimalStruct const& b, com_array<winrt::WinRTComponent::MinimalStruct>& array);
        static void OutputInterface(winrt::WinRTComponent::IMinimalInterface const& a, winrt::WinRTComponent::IMinimalInterface const& b, com_array<winrt::WinRTComponent::IMinimalInterface>& array);
        static void OutputClass(winrt::WinRTComponent::MinimalClass const& a, winrt::WinRTComponent::MinimalClass const& b, com_array<winrt::WinRTComponent::MinimalClass>& array);
        static void OutputDelegate(winrt::WinRTComponent::MinimalDelegate const& a, winrt::WinRTComponent::MinimalDelegate const& b, com_array<winrt::WinRTComponent::MinimalDelegate>& array);
        static void SwapFirstLastInt32(array_view<int32_t> array);
        static void SwapFirstLastString(array_view<hstring> array);
        static void SwapFirstLastObject(array_view<winrt::Windows::Foundation::IInspectable> array);
        static void SwapFirstLastEnum(array_view<winrt::WinRTComponent::MinimalEnum> array);
        static void SwapFirstLastStruct(array_view<winrt::WinRTComponent::MinimalStruct> array);
        static void SwapFirstLastInterface(array_view<winrt::WinRTComponent::IMinimalInterface> array);
        static void SwapFirstLastClass(array_view<winrt::WinRTComponent::MinimalClass> array);
        static void SwapFirstLastDelegate(array_view<winrt::WinRTComponent::MinimalDelegate> array);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Arrays : ArraysT<Arrays, implementation::Arrays>
    {
    };
}
