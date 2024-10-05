#pragma once
#include "ObjectReferencer.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ObjectReferencer : ObjectReferencerT<ObjectReferencer>
    {
        ObjectReferencer(winrt::Windows::Foundation::IInspectable const& obj);

        winrt::Windows::Foundation::IInspectable Target();
        void Clear();
        uint32_t CallAddRef();
        uint32_t CallRelease();

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
