#include "pch.h"
#include "MinimalDelegate.g.h"
#include "DestructionCallback.g.h"
#include "DestructionCallback.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    struct DestructionCallback : DestructionCallbackT<DestructionCallback>
    {
        DestructionCallback(winrt::WinRTComponent::MinimalDelegate const& callback) : m_callback(callback) {}
        ~DestructionCallback() { m_callback(); }

        winrt::WinRTComponent::MinimalDelegate m_callback;
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct DestructionCallback : DestructionCallbackT<DestructionCallback, implementation::DestructionCallback>
    {
    };
}
