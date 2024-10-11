#include "pch.h"
#include "Int32Wrapper.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Int32Wrapper : Int32WrapperT<Int32Wrapper>
    {
        int32_t GetSet() { return _value; }
        void GetSet(int32_t value) { _value = value; }
        int32_t GetOnly() { return _value; }

    private:
        int32_t _value = 0;
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Int32Wrapper : Int32WrapperT<Int32Wrapper, implementation::Int32Wrapper>
    {
    };
}

#include "Int32Wrapper.g.cpp"