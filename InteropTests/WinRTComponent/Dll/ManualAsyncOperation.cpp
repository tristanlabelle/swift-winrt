#include "pch.h"
#include "ManualAsyncOperation.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ManualAsyncOperation : ManualAsyncOperationT<ManualAsyncOperation>
    {
        ManualAsyncOperation(int32_t id) : id(id) {}

        uint32_t Id() { return id; }
        winrt::Windows::Foundation::AsyncStatus Status() { return status; }
        winrt::hresult ErrorCode() { return errorCode; }

        void Completed(winrt::Windows::Foundation::AsyncOperationCompletedHandler<int32_t> const& handler)
        {
            if (completedHandler != nullptr) throw winrt::hresult_illegal_method_call();
            completedHandler = handler;
            if (handler && status != winrt::Windows::Foundation::AsyncStatus::Started)
                handler(*this, status);
        }

        winrt::Windows::Foundation::AsyncOperationCompletedHandler<int32_t> Completed() { return completedHandler; }

        #pragma warning(suppress: 4458) // declaration of 'result' hides class member
        void Complete(int32_t result)
        {
            if (status != winrt::Windows::Foundation::AsyncStatus::Started) throw winrt::hresult_illegal_method_call();
            this->result = result;
            status = winrt::Windows::Foundation::AsyncStatus::Completed;
            if (completedHandler) completedHandler(*this, status);
        }

        #pragma warning(suppress: 4458) // declaration of 'errorCode' hides class member
        void CompleteWithError(winrt::hresult const& errorCode)
        {
            if (status != winrt::Windows::Foundation::AsyncStatus::Started) throw winrt::hresult_illegal_method_call();
            this->errorCode = errorCode;
            status = winrt::Windows::Foundation::AsyncStatus::Error;
            if (completedHandler) completedHandler(*this, status);
        }

        void Cancel()
        {
            if (status != winrt::Windows::Foundation::AsyncStatus::Started)
            {
                status = winrt::Windows::Foundation::AsyncStatus::Canceled;
                if (completedHandler) completedHandler(*this, status);
            }
        }

        int32_t GetResults()
        {
            switch (status)
            {
                case winrt::Windows::Foundation::AsyncStatus::Completed: return result;
                case winrt::Windows::Foundation::AsyncStatus::Canceled: throw winrt::hresult_canceled();
                case winrt::Windows::Foundation::AsyncStatus::Error: throw winrt::hresult_error(errorCode);
                default: throw winrt::hresult_illegal_method_call();
            }
        }

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

#include "ManualAsyncOperation.g.cpp"