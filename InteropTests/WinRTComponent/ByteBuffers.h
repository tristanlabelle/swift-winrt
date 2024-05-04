#pragma once
#include "ByteBuffers.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ByteBuffers
    {
        ByteBuffers() = default;

        static winrt::Windows::Foundation::IMemoryBuffer CreateMemoryBuffer(array_view<uint8_t const> data);
        static com_array<uint8_t> GetMemoryBufferReferenceBytes(winrt::Windows::Foundation::IMemoryBufferReference const& reference);
        static winrt::Windows::Storage::Streams::IBuffer CreateBuffer(array_view<uint8_t const> data);
        static com_array<uint8_t> GetBufferBytes(winrt::Windows::Storage::Streams::IBuffer const& buffer);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ByteBuffers : ByteBuffersT<ByteBuffers, implementation::ByteBuffers>
    {
    };
}
