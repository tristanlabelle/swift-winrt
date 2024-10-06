#pragma once
#include "Enums.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Enums
    {
        Enums() = default;

        static FlagsEnum BitwiseAnd(FlagsEnum lhs, FlagsEnum rhs);
        static FlagsEnum BitwiseOr(FlagsEnum lhs, FlagsEnum rhs);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Enums : EnumsT<Enums, implementation::Enums>
    {
    };
}
