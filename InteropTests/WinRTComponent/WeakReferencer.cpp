#include "pch.h"
#include "WeakReferencer.h"
#include "WeakReferencer.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    WeakReferencer::WeakReferencer(winrt::Windows::Foundation::IInspectable const& target)
    {
        this->target = winrt::make_weak(target);
    }
    winrt::Windows::Foundation::IInspectable WeakReferencer::Target()
    {
        return target.get();
    }
}
