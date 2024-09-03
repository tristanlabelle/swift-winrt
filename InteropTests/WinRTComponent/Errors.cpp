#include "pch.h"
#include "Errors.h"
#include "Errors.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    void Errors::FailWith(winrt::hresult const& hr, winrt::hstring const& message)
    {
        throw winrt::hresult_error(hr, message);
    }
    hstring Errors::NotImplementedProperty()
    {
        throw winrt::hresult_not_implemented();
    }
    void Errors::NotImplementedProperty(hstring const&)
    {
        throw winrt::hresult_not_implemented();
    }
    void Errors::Call(winrt::WinRTComponent::MinimalDelegate const& callee)
    {
        callee();
    }
    winrt::hresult Errors::CatchHResult(winrt::WinRTComponent::MinimalDelegate const& callee)
    {
        try { callee(); }
        catch (const winrt::hresult_error& error) { return error.code(); }
        return winrt::hresult();
    }
    winrt::hstring Errors::CatchMessage(winrt::WinRTComponent::MinimalDelegate const& callee)
    {
        try { callee(); }
        catch (const winrt::hresult_error& error) { return error.message(); }
        return winrt::hstring();
    }
}
