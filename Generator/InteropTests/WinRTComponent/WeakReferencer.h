#pragma once
#include "WeakReferencer.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct WeakReferencer : WeakReferencerT<WeakReferencer>
    {
        WeakReferencer(winrt::Windows::Foundation::IInspectable const& target);
        winrt::Windows::Foundation::IInspectable Target();
    
    private:
        winrt::weak_ref<winrt::Windows::Foundation::IInspectable> target;
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct WeakReferencer : WeakReferencerT<WeakReferencer, implementation::WeakReferencer>
    {
    };
}
