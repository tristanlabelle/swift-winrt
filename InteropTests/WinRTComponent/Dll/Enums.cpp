#include "pch.h"
#include "Enums.h"
#include "Enums.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    FlagsEnum Enums::BitwiseNot(FlagsEnum value)
    {
        return ~value;
    }

    FlagsEnum Enums::BitwiseAnd(FlagsEnum lhs, FlagsEnum rhs)
    {
        return lhs & rhs;
    }

    FlagsEnum Enums::BitwiseOr(FlagsEnum lhs, FlagsEnum rhs)
    {
        return lhs | rhs;
    }

    FlagsEnum Enums::BitwiseXor(FlagsEnum lhs, FlagsEnum rhs)
    {
        return lhs ^ rhs;
    }
}
