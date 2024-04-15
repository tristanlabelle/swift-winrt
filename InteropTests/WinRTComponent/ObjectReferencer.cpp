#include "pch.h"
#include "ObjectReferencer.h"
#include "ObjectReferencer.g.cpp"
#include <inspectable.h>

namespace winrt::WinRTComponent::implementation
{
    ObjectReferencer::ObjectReferencer(winrt::Windows::Foundation::IInspectable const& obj)
    {
        m_object = obj;
    }
    winrt::Windows::Foundation::IInspectable ObjectReferencer::Target()
    {
        return m_object;
    }
    void ObjectReferencer::Clear()
    {
        m_object = nullptr;
    }
    uint32_t ObjectReferencer::CallAddRef()
    {
        return winrt::get_unknown(m_object)->AddRef();
    }
    uint32_t ObjectReferencer::CallRelease()
    {
        return winrt::get_unknown(m_object)->Release();
    }
}
