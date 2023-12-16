#include "pch.h"
#include "Overloading.h"
#include "Overloading.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    int32_t Overloading::Sum() { return 0; }
    int32_t Overloading::Sum(int32_t a) { return a; }
    int32_t Overloading::Sum(int32_t a, int32_t b) { return a + b; }
}
