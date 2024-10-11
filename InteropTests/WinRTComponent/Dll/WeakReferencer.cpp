#include "pch.h"
#include "WeakReferencer.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct WeakReferencer : WeakReferencerT<WeakReferencer>
    {
        WeakReferencer(winrt::Windows::Foundation::IInspectable const& target)
        {
            this->target = winrt::make_weak(target);
        }

        winrt::Windows::Foundation::IInspectable Target()
        {
            return target.get();
        }
    
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

#include "WeakReferencer.g.cpp"