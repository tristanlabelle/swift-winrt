#include "pch.h"
#include "MinimalBaseClass.g.h"
#include "MinimalDerivedClass.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct MinimalBaseClass : MinimalBaseClassT<MinimalBaseClass>
    {
        virtual winrt::hstring TypeName() { return L"MinimalBaseClass"; }

        static winrt::WinRTComponent::MinimalBaseClass CreateBase();
        static winrt::WinRTComponent::MinimalBaseClass CreateDerivedAsBase();
        static winrt::WinRTComponent::MinimalBaseClass CreatePrivate();

        static winrt::WinRTComponent::MinimalBaseClass Passthrough(winrt::WinRTComponent::MinimalBaseClass const& value)
        {
            return value;
        }

        static winrt::hstring GetTypeName(winrt::WinRTComponent::MinimalBaseClass const& value)
        {
            return value.TypeName();
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalBaseClass : MinimalBaseClassT<MinimalBaseClass, implementation::MinimalBaseClass>
    {
    };
}

namespace winrt::WinRTComponent::implementation
{
    struct MinimalDerivedClass : MinimalDerivedClassT<MinimalDerivedClass, WinRTComponent::implementation::MinimalBaseClass>
    {
        virtual winrt::hstring TypeName() override { return L"MinimalDerivedClass"; }

        static winrt::WinRTComponent::MinimalDerivedClass CreateDerived();
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalDerivedClass : MinimalDerivedClassT<MinimalDerivedClass, implementation::MinimalDerivedClass>
    {
    };
}

namespace
{
    struct PrivateClass: winrt::WinRTComponent::implementation::MinimalBaseClass
    {
        winrt::hstring TypeName() override { return L"PrivateClass"; }
    };
}

namespace winrt::WinRTComponent::implementation
{
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
    winrt::WinRTComponent::MinimalDerivedClass MinimalDerivedClass::CreateDerived()
    {
        return winrt::make<MinimalDerivedClass>();
    }
}

#include "MinimalBaseClass.g.cpp"
#include "MinimalDerivedClass.g.cpp"