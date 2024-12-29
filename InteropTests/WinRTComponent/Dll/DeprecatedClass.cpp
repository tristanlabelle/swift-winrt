#include "pch.h"
#include "DeprecatedClass.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct DeprecatedClass : DeprecatedClassT<DeprecatedClass>
    {
        DeprecatedClass(int32_t) {}
        void Method() {}
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct DeprecatedClass : DeprecatedClassT<DeprecatedClass, implementation::DeprecatedClass>
    {
    };
}

#include "DeprecatedClass.g.cpp"