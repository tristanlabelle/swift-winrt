#include "pch.h"
#include "ObjectReferencer.g.h"
#include <inspectable.h>

namespace winrt::WinRTComponent::implementation
{
    struct ObjectReferencer : ObjectReferencerT<ObjectReferencer>
    {
        ObjectReferencer(winrt::Windows::Foundation::IInspectable const& obj)
        {
            m_object = obj;
        }

        winrt::Windows::Foundation::IInspectable Target() { return m_object; }
        void Clear() { m_object = nullptr; }

        uint32_t CallAddRef()
        {
            return winrt::get_unknown(m_object)->AddRef();
        }

        uint32_t CallRelease()
        {
            return winrt::get_unknown(m_object)->Release();
        }

    private:
        winrt::Windows::Foundation::IInspectable m_object = nullptr;
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct ObjectReferencer : ObjectReferencerT<ObjectReferencer, implementation::ObjectReferencer>
    {
    };
}

#include "ObjectReferencer.g.cpp"