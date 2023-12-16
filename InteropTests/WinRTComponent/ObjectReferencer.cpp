#include "pch.h"
#include "ObjectReferencer.h"
#include "ObjectReferencer.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    ObjectReferencer::~ObjectReferencer() noexcept {
        if (m_object != nullptr) m_object->Release();
    }
    void ObjectReferencer::Begin(winrt::Windows::Foundation::IInspectable const& obj)
    {
        assert(m_object == nullptr);
        m_object = winrt::get_unknown(obj);
        m_object->AddRef();
    }
    uint32_t ObjectReferencer::CallAddRef()
    {
        assert(m_object != nullptr && "Begin() must be called first");
        return m_object->AddRef();
    }
    uint32_t ObjectReferencer::CallRelease()
    {
        assert(m_object != nullptr && "Begin() must be called first");
        return m_object->Release();
    }
    uint32_t ObjectReferencer::End()
    {
        assert(m_object != nullptr && "Begin() must be called first");
        auto refCount = m_object->Release();
        m_object = nullptr;
        return refCount;
    }
}
