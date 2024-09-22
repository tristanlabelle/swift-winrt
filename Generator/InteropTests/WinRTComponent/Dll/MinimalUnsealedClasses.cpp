#include "pch.h"
#include "MinimalUnsealedClasses.h"
#include "MinimalBaseClass.g.cpp"
#include "MinimalDerivedClass.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    struct PrivateClass: MinimalBaseClass
    {
        winrt::hstring TypeName() override { return L"PrivateClass"; }
    };

    winrt::hstring MinimalBaseClass::TypeName()
    {
        return L"MinimalBaseClass";
    }
    winrt::WinRTComponent::MinimalBaseClass MinimalBaseClass::CreateBase()
    {
        return winrt::make<MinimalBaseClass>();
    }
    winrt::WinRTComponent::MinimalBaseClass MinimalBaseClass::CreateDerivedAsBase()
    {
        return winrt::make<MinimalDerivedClass>();
    }
    winrt::WinRTComponent::MinimalBaseClass MinimalBaseClass::CreatePrivate()
    {
        return winrt::make<PrivateClass>();
    }
    winrt::WinRTComponent::MinimalBaseClass MinimalBaseClass::Passthrough(winrt::WinRTComponent::MinimalBaseClass const& value)
    {
        return value;
    }
    winrt::hstring MinimalBaseClass::GetTypeName(winrt::WinRTComponent::MinimalBaseClass const& value)
    {
        return value.TypeName();
    }
}

namespace winrt::WinRTComponent::implementation
{
    winrt::hstring MinimalDerivedClass::TypeName()
    {
        return L"MinimalDerivedClass";
    }
    winrt::WinRTComponent::MinimalDerivedClass MinimalDerivedClass::CreateDerived()
    {
        return winrt::make<MinimalDerivedClass>();
    }
}
