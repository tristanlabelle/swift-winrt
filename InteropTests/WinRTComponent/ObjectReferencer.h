#pragma once
#include "ObjectReferencer.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ObjectReferencer : ObjectReferencerT<ObjectReferencer>
    {
        ObjectReferencer(winrt::Windows::Foundation::IInspectable const& obj);
        ~ObjectReferencer() noexcept;

        uint32_t CallAddRef();
        uint32_t CallRelease();

    private:
        ::IUnknown* m_object = nullptr;
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ObjectReferencer : ObjectReferencerT<ObjectReferencer, implementation::ObjectReferencer>
    {
    };
}
