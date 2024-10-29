#include "pch.h"
#include "MinimalBaseClass.g.h"
#include "MinimalDerivedClass.g.h"
#include "MinimalBaseClassHierarchy.g.h"

// MinimalBaseClass
namespace winrt::WinRTComponent::implementation
{
    struct MinimalBaseClass : MinimalBaseClassT<MinimalBaseClass>
    {
        virtual winrt::hstring TypeName() { return L"MinimalBaseClass"; }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalBaseClass : MinimalBaseClassT<MinimalBaseClass, implementation::MinimalBaseClass>
    {
    };
}

// MinimalDerivedClass
namespace winrt::WinRTComponent::implementation
{
    struct MinimalDerivedClass : MinimalDerivedClassT<MinimalDerivedClass, WinRTComponent::implementation::MinimalBaseClass>
    {
        virtual winrt::hstring TypeName() override { return L"MinimalDerivedClass"; }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalDerivedClass : MinimalDerivedClassT<MinimalDerivedClass, implementation::MinimalDerivedClass>
    {
    };
}

// MinimalBaseClassHierarchy
namespace winrt::WinRTComponent::implementation
{
    namespace
    {
        struct PrivateDerivedClass: winrt::WinRTComponent::implementation::MinimalBaseClass
        {
            winrt::hstring TypeName() override { return L"PrivateDerivedClass"; }
        };
    }

    struct MinimalBaseClassHierarchy : MinimalBaseClassHierarchyT<MinimalBaseClass>
    {
        static winrt::WinRTComponent::MinimalBaseClass CreateBase()
        {
            return winrt::make<MinimalBaseClass>();
        }

        static winrt::WinRTComponent::MinimalDerivedClass CreateDerived()
        {
            return winrt::make<MinimalDerivedClass>();
        }

        static winrt::WinRTComponent::MinimalBaseClass CreateDerivedAsBase()
        {
            return winrt::make<MinimalDerivedClass>();
        }

        static winrt::WinRTComponent::MinimalBaseClass CreatePrivateDerived()
        {
            return winrt::make<PrivateDerivedClass>();
        }

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
    struct MinimalBaseClassHierarchy : MinimalBaseClassHierarchyT<MinimalBaseClassHierarchy, implementation::MinimalBaseClassHierarchy>
    {
    };
}

#include "MinimalBaseClass.g.cpp"
#include "MinimalDerivedClass.g.cpp"
#include "MinimalBaseClassHierarchy.g.cpp"