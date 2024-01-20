#include "pch.h"
#include "MinimalUnsealedClass.h"
#include "MinimalUnsealedClass.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    struct Derived: MinimalUnsealedClass
    {
        bool IsDerived() override { return true; }
    };

    bool MinimalUnsealedClass::IsDerived()
    {
        return false;
    }
    winrt::WinRTComponent::MinimalUnsealedClass MinimalUnsealedClass::Create()
    {
        return winrt::make<MinimalUnsealedClass>();
    }
    winrt::WinRTComponent::MinimalUnsealedClass MinimalUnsealedClass::CreateDerived()
    {
        return winrt::make<Derived>();
    }
    winrt::WinRTComponent::MinimalUnsealedClass MinimalUnsealedClass::Passthrough(winrt::WinRTComponent::MinimalUnsealedClass const& value)
    {
        return value;
    }
    bool MinimalUnsealedClass::GetIsDerived(winrt::WinRTComponent::MinimalUnsealedClass const& value)
    {
        return value.IsDerived();
    }
}
