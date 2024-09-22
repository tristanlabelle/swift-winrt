#pragma once
#include "ByteBuffers.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ByteBuffers
    {
        ByteBuffers() = default;

        static com_array<uint8_t> MemoryBufferToArray(winrt::Windows::Foundation::IMemoryBuffer const& buffer);
        static com_array<uint8_t> StorageBufferToArray(winrt::Windows::Storage::Streams::IBuffer const& buffer);
        static winrt::Windows::Foundation::IMemoryBuffer ArrayToMemoryBuffer(array_view<uint8_t const> bytes);
        static winrt::Windows::Storage::Streams::IBuffer ArrayToStorageBuffer(array_view<uint8_t const> bytes);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ByteBuffers : ByteBuffersT<ByteBuffers, implementation::ByteBuffers>
    {
    };
}
