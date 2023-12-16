#pragma once
#include "ObjectReferencer.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ObjectReferencer : ObjectReferencerT<ObjectReferencer>
    {
        ObjectReferencer() = default;
        ~ObjectReferencer() noexcept;

        void Begin(winrt::Windows::Foundation::IInspectable const& obj);
        uint32_t CallAddRef();
        uint32_t CallRelease();
        uint32_t End();

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
