#pragma once
#include "StrongReferencer.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct StrongReferencer : StrongReferencerT<StrongReferencer>
    {
        StrongReferencer(winrt::Windows::Foundation::IInspectable const& target);
        winrt::Windows::Foundation::IInspectable Target();
        void Clear();
    
    private:
        winrt::Windows::Foundation::IInspectable target;
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct StrongReferencer : StrongReferencerT<StrongReferencer, implementation::StrongReferencer>
    {
    };
}
