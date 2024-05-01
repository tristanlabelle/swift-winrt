#pragma once
#include "ByteBuffers.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ByteBuffers
    {
        ByteBuffers() = default;

        static winrt::Windows::Foundation::IMemoryBuffer CreateMemoryBuffer(array_view<uint8_t const> data);
        static com_array<uint8_t> GetMemoryBufferBytes(winrt::Windows::Foundation::IMemoryBufferReference const& bufferReference);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ByteBuffers : ByteBuffersT<ByteBuffers, implementation::ByteBuffers>
    {
    };
}
