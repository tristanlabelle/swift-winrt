#include "pch.h"
#include "OverloadedSum.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct OverloadedSum : OverloadedSumT<OverloadedSum>
    {
        OverloadedSum() : m_result(0) {}
        OverloadedSum(int32_t a) : m_result(a) {}
        OverloadedSum(int32_t a, int32_t b) : m_result(a + b) {}

        int32_t Result() { return m_result; }

        static int32_t Of() { return 0; }
        static int32_t Of(int32_t a) { return a; }
        static int32_t Of(int32_t a, int32_t b) { return a + b; }

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

#include "OverloadedSum.g.cpp"