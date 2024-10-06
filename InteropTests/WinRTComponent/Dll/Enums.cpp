#include "pch.h"
#include "Enums.h"
#include "Enums.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    FlagsEnum Enums::BitwiseAnd(FlagsEnum lhs, FlagsEnum rhs)
    {
        return value & flags;
    }

    FlagsEnum Enums::BitwiseOr(FlagsEnum lhs, FlagsEnum rhs)
    {
        return value | flags;
    }
}
