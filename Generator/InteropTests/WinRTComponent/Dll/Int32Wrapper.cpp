#include "pch.h"
#include "Int32Wrapper.h"
#include "Int32Wrapper.g.cpp"
#include "Int32Global.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    int32_t Int32Wrapper::GetSet()
    {
        return _value;
    }
    void Int32Wrapper::GetSet(int32_t value)
    {
        _value = value;
    }
    int32_t Int32Wrapper::GetOnly()
    {
        return _value;
    }

    int32_t Int32Global::_value = false;
    int32_t Int32Global::GetSet()
    {
        return _value;
    }
    void Int32Global::GetSet(int32_t value)
    {
        Int32Global::_value = value;
    }
    int32_t Int32Global::GetOnly()
    {
        return _value;
    }
}
