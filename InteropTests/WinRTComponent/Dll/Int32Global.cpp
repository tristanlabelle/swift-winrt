#include "pch.h"
#include "Int32Global.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Int32Global
    {
        static int32_t GetOnly() { return _value; }
        static int32_t GetSet() { return _value; }
        static void GetSet(int32_t value) { _value = value; }

    private:
        static int32_t _value;
    };

    int32_t Int32Global::_value = 0;
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Int32Global : Int32GlobalT<Int32Global, implementation::Int32Global>
    {
    };
}

#include "Int32Global.g.cpp"