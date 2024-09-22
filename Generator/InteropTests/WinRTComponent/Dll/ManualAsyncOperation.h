#pragma once
#include "ManualAsyncOperation.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ManualAsyncOperation : ManualAsyncOperationT<ManualAsyncOperation>
    {
        ManualAsyncOperation(int32_t id) : id(id) {};

        uint32_t Id() { return id; }
        winrt::Windows::Foundation::AsyncStatus Status() { return status; }
        winrt::hresult ErrorCode() { return errorCode; }
        void Completed(winrt::Windows::Foundation::AsyncOperationCompletedHandler<int32_t> const& handler);
        winrt::Windows::Foundation::AsyncOperationCompletedHandler<int32_t> Completed() { return completedHandler; }

        void Complete(int32_t result);
        void CompleteWithError(winrt::hresult const& errorCode);
        void Cancel();
        int32_t GetResults();
        void Close() {}

    private:
        const int32_t id;
        winrt::Windows::Foundation::AsyncStatus status = winrt::Windows::Foundation::AsyncStatus::Started;
        winrt::hresult errorCode = E_PENDING;
        int32_t result = 0;
        winrt::Windows::Foundation::AsyncOperationCompletedHandler<int32_t> completedHandler;
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ManualAsyncOperation : ManualAsyncOperationT<ManualAsyncOperation, implementation::ManualAsyncOperation>
    {
    };
}
