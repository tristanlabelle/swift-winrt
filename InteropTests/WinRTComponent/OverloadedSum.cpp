#include "pch.h"
#include "OverloadedSum.h"
#include "OverloadedSum.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    OverloadedSum::OverloadedSum() : m_result(0) {}
    OverloadedSum::OverloadedSum(int32_t a) : m_result(a) {}
    OverloadedSum::OverloadedSum(int32_t a, int32_t b) : m_result(a + b) {}

    int32_t OverloadedSum::Result() { return m_result; }

    int32_t OverloadedSum::Of() { return 0; }
    int32_t OverloadedSum::Of(int32_t a) { return a; }
    int32_t OverloadedSum::Of(int32_t a, int32_t b) { return a + b; }
}
