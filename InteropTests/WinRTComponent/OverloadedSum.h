#pragma once
#include "OverloadedSum.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct OverloadedSum : OverloadedSumT<OverloadedSum>
    {
        OverloadedSum();
        OverloadedSum(int32_t a);
        OverloadedSum(int32_t a, int32_t b);

        int32_t Result();

        static int32_t Of();
        static int32_t Of(int32_t a);
        static int32_t Of(int32_t a, int32_t b);

    private:
        int32_t m_result = 0;
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct OverloadedSum : OverloadedSumT<OverloadedSum, implementation::OverloadedSum>
    {
    };
}
