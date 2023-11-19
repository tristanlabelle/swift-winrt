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
    winrt::hresult Errors::Catch(winrt::WinRTComponent::MinimalDelegate const& callee)
    {
        try { callee(); }
        catch (const winrt::hresult_error& error) { return error.code(); }
        return winrt::hresult();
    }
}
