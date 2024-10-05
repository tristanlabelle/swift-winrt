#pragma once
#include "Int32Wrapper.g.h"
#include "Int32Global.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Int32Wrapper : Int32WrapperT<Int32Wrapper>
    {
        Int32Wrapper() = default;

        int32_t GetSet();
        void GetSet(int32_t value);
        int32_t GetOnly();

    private:
        int32_t _value = 0;
    };

    struct Int32Global
    {
        Int32Global() = default;

        static int32_t GetOnly();
        static int32_t GetSet();
        static void GetSet(int32_t value);

    private:
        static int32_t _value;
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Int32Wrapper : Int32WrapperT<Int32Wrapper, implementation::Int32Wrapper>
    {
    };

    struct Int32Global : Int32GlobalT<Int32Global, implementation::Int32Global>
    {
    };
}
