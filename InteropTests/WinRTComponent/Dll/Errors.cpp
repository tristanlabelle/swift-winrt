#include "pch.h"
#include "Errors.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Errors
    {
        static void FailWith(winrt::hresult const& hr, winrt::hstring const& message)
        {
            throw winrt::hresult_error(hr, message);
        }

        static hstring NotImplementedProperty()
        {
            throw winrt::hresult_not_implemented();
        }

        static void NotImplementedProperty(hstring const&)
        {
            throw winrt::hresult_not_implemented();
        }

        static void Call(winrt::WinRTComponent::MinimalDelegate const& callee)
        {
            callee();
        }

        static winrt::hresult CatchHResult(winrt::WinRTComponent::MinimalDelegate const& callee)
        {
            try { callee(); }
            catch (const winrt::hresult_error& error) { return error.code(); }
            return winrt::hresult();
        }

        static winrt::hstring CatchMessage(winrt::WinRTComponent::MinimalDelegate const& callee)
        {
            try { callee(); }
            catch (const winrt::hresult_error& error) { return error.message(); }
            return winrt::hstring();
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Errors : ErrorsT<Errors, implementation::Errors>
    {
    };
}

#include "Errors.g.cpp"