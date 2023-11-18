#pragma once
#include "Arrays.g.h"

namespace winrt::TestComponent::implementation
{
    struct Arrays
    {
        Arrays() = default;

        static int32_t GetLastInt32(array_view<int32_t const> value);
        static hstring GetLastString(array_view<hstring const> value);
        static winrt::Windows::Foundation::IInspectable GetLastObject(array_view<winrt::Windows::Foundation::IInspectable const> value);
        static winrt::TestComponent::MinimalEnum GetLastEnum(array_view<winrt::TestComponent::MinimalEnum const> value);
        static winrt::TestComponent::MinimalStruct GetLastStruct(array_view<winrt::TestComponent::MinimalStruct const> value);
        static winrt::TestComponent::IMinimalInterface GetLastInterface(array_view<winrt::TestComponent::IMinimalInterface const> value);
        static winrt::TestComponent::MinimalClass GetLastClass(array_view<winrt::TestComponent::MinimalClass const> value);
        static winrt::TestComponent::MinimalDelegate GetLastDelegate(array_view<winrt::TestComponent::MinimalDelegate const> value);
        static com_array<int32_t> MakeInt32(int32_t a, int32_t b);
        static com_array<hstring> MakeString(hstring const& a, hstring const& b);
        static com_array<winrt::Windows::Foundation::IInspectable> MakeObject(winrt::Windows::Foundation::IInspectable const& a, winrt::Windows::Foundation::IInspectable const& b);
        static com_array<winrt::TestComponent::MinimalEnum> MakeEnum(winrt::TestComponent::MinimalEnum const& a, winrt::TestComponent::MinimalEnum const& b);
        static com_array<winrt::TestComponent::MinimalStruct> MakeStruct(winrt::TestComponent::MinimalStruct const& a, winrt::TestComponent::MinimalStruct const& b);
        static com_array<winrt::TestComponent::IMinimalInterface> MakeInterface(winrt::TestComponent::IMinimalInterface const& a, winrt::TestComponent::IMinimalInterface const& b);
        static com_array<winrt::TestComponent::MinimalClass> MakeClass(winrt::TestComponent::MinimalClass const& a, winrt::TestComponent::MinimalClass const& b);
        static com_array<winrt::TestComponent::MinimalDelegate> MakeDelegate(winrt::TestComponent::MinimalDelegate const& a, winrt::TestComponent::MinimalDelegate const& b);
        static void OutputInt32(int32_t a, int32_t b, com_array<int32_t>& array);
        static void OutputString(hstring const& a, hstring const& b, com_array<hstring>& array);
        static void OutputObject(winrt::Windows::Foundation::IInspectable const& a, winrt::Windows::Foundation::IInspectable const& b, com_array<winrt::Windows::Foundation::IInspectable>& array);
        static void OutputEnum(winrt::TestComponent::MinimalEnum const& a, winrt::TestComponent::MinimalEnum const& b, com_array<winrt::TestComponent::MinimalEnum>& array);
        static void OutputStruct(winrt::TestComponent::MinimalStruct const& a, winrt::TestComponent::MinimalStruct const& b, com_array<winrt::TestComponent::MinimalStruct>& array);
        static void OutputInterface(winrt::TestComponent::IMinimalInterface const& a, winrt::TestComponent::IMinimalInterface const& b, com_array<winrt::TestComponent::IMinimalInterface>& array);
        static void OutputClass(winrt::TestComponent::MinimalClass const& a, winrt::TestComponent::MinimalClass const& b, com_array<winrt::TestComponent::MinimalClass>& array);
        static void OutputDelegate(winrt::TestComponent::MinimalDelegate const& a, winrt::TestComponent::MinimalDelegate const& b, com_array<winrt::TestComponent::MinimalDelegate>& array);
        static void SwapFirstLastInt32(array_view<int32_t> array);
        static void SwapFirstLastString(array_view<hstring> array);
        static void SwapFirstLastObject(array_view<winrt::Windows::Foundation::IInspectable> array);
        static void SwapFirstLastEnum(array_view<winrt::TestComponent::MinimalEnum> array);
        static void SwapFirstLastStruct(array_view<winrt::TestComponent::MinimalStruct> array);
        static void SwapFirstLastInterface(array_view<winrt::TestComponent::IMinimalInterface> array);
        static void SwapFirstLastClass(array_view<winrt::TestComponent::MinimalClass> array);
        static void SwapFirstLastDelegate(array_view<winrt::TestComponent::MinimalDelegate> array);
    };
}
namespace winrt::TestComponent::factory_implementation
{
    struct Arrays : ArraysT<Arrays, implementation::Arrays>
    {
    };
}
