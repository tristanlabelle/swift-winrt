#include "pch.h"
#include "MinimalBaseClass.g.h"
#include "MinimalUnsealedDerivedClass.g.h"
#include "MinimalSealedDerivedClass.g.h"
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

// MinimalUnsealedDerivedClass
namespace winrt::WinRTComponent::implementation
{
    struct MinimalUnsealedDerivedClass : MinimalUnsealedDerivedClassT<MinimalUnsealedDerivedClass, MinimalBaseClass>
    {
        virtual winrt::hstring TypeName() override { return L"MinimalUnsealedDerivedClass"; }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalUnsealedDerivedClass : MinimalUnsealedDerivedClassT<MinimalUnsealedDerivedClass, implementation::MinimalUnsealedDerivedClass>
    {
    };
}

// MinimalSealedDerivedClass
namespace winrt::WinRTComponent::implementation
{
    struct MinimalSealedDerivedClass : MinimalSealedDerivedClassT<MinimalSealedDerivedClass, MinimalBaseClass>
    {
        virtual winrt::hstring TypeName() override { return L"MinimalSealedDerivedClass"; }
        void Dummy() {}
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalSealedDerivedClass : MinimalSealedDerivedClassT<MinimalSealedDerivedClass, implementation::MinimalSealedDerivedClass>
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

    struct MinimalBaseClassHierarchy
    {
        static winrt::WinRTComponent::MinimalBaseClass CreateBase()
        {
            return winrt::make<MinimalBaseClass>();
        }

        static winrt::WinRTComponent::MinimalUnsealedDerivedClass CreateUnsealedDerived()
        {
            return winrt::make<MinimalUnsealedDerivedClass>();
        }

        static winrt::WinRTComponent::MinimalBaseClass CreateUnsealedDerivedAsBase()
        {
            return winrt::make<MinimalUnsealedDerivedClass>();
        }

        static winrt::WinRTComponent::MinimalSealedDerivedClass CreateSealedDerived()
        {
            return winrt::make<MinimalSealedDerivedClass>();
        }

        static winrt::WinRTComponent::MinimalBaseClass CreateSealedDerivedAsBase()
        {
            return winrt::make<MinimalSealedDerivedClass>();
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
#include "MinimalUnsealedDerivedClass.g.cpp"
#include "MinimalSealedDerivedClass.g.cpp"
#include "MinimalBaseClassHierarchy.g.cpp"