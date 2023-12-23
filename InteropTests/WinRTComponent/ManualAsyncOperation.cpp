#include "pch.h"
#include "ManualAsyncOperation.h"
#include "ManualAsyncOperation.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    void ManualAsyncOperation::Completed(winrt::Windows::Foundation::AsyncOperationCompletedHandler<int32_t> const& handler)
    {
        if (completedHandler != nullptr) throw winrt::hresult_illegal_method_call();
        completedHandler = handler;
        if (handler && status != winrt::Windows::Foundation::AsyncStatus::Started)
            handler(*this, status);
    }

    #pragma warning(suppress: 4458) // declaration of 'result' hides class member
    void ManualAsyncOperation::Complete(int32_t result)
    {
        if (status != winrt::Windows::Foundation::AsyncStatus::Started) throw winrt::hresult_illegal_method_call();
        this->result = result;
        status = winrt::Windows::Foundation::AsyncStatus::Completed;
        if (completedHandler) completedHandler(*this, status);
    }

    #pragma warning(suppress: 4458) // declaration of 'errorCode' hides class member
    void ManualAsyncOperation::CompleteWithError(winrt::hresult const& errorCode)
    {
        if (status != winrt::Windows::Foundation::AsyncStatus::Started) throw winrt::hresult_illegal_method_call();
        this->errorCode = errorCode;
        status = winrt::Windows::Foundation::AsyncStatus::Error;
        if (completedHandler) completedHandler(*this, status);
    }

    void ManualAsyncOperation::Cancel()
    {
        if (status != winrt::Windows::Foundation::AsyncStatus::Started)
        {
            status = winrt::Windows::Foundation::AsyncStatus::Canceled;
            if (completedHandler) completedHandler(*this, status);
        }
    }

    int32_t ManualAsyncOperation::GetResults()
    {
        switch (status)
        {
            case winrt::Windows::Foundation::AsyncStatus::Completed: return result;
            case winrt::Windows::Foundation::AsyncStatus::Canceled: throw winrt::hresult_canceled();
            case winrt::Windows::Foundation::AsyncStatus::Error: throw winrt::hresult_error(errorCode);
            default: throw winrt::hresult_illegal_method_call();
        }
    }
}
