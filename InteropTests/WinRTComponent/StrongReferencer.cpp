#include "pch.h"
#include "StrongReferencer.h"
#include "StrongReferencer.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    StrongReferencer::StrongReferencer(winrt::Windows::Foundation::IInspectable const& target)
    {
        this->target = target;
    }
    winrt::Windows::Foundation::IInspectable StrongReferencer::Target()
    {
        return target;
    }
    void StrongReferencer::Clear()
    {
        target = nullptr;
    }
}
