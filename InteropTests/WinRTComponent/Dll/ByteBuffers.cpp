#include "pch.h"
#include "ByteBuffers.g.h"
#include <winrt/Windows.Storage.Streams.h>

namespace winrt::WinRTComponent::implementation
{
    struct ByteBuffers
    {
        static com_array<uint8_t> MemoryBufferToArray(winrt::Windows::Foundation::IMemoryBuffer const& buffer)
        {
            auto bufferReference = buffer.CreateReference();
            auto data = bufferReference.data();
            return { data, data + bufferReference.Capacity() };
        }

        static com_array<uint8_t> StorageBufferToArray(winrt::Windows::Storage::Streams::IBuffer const& buffer)
        {
            auto data = buffer.data();
            return { data, data + buffer.Length() };
        }

        static winrt::Windows::Foundation::IMemoryBuffer ArrayToMemoryBuffer(array_view<uint8_t const> bytes)
        {
            winrt::Windows::Foundation::MemoryBuffer buffer(bytes.size());
            memcpy(buffer.CreateReference().data(), bytes.data(), bytes.size());
            return buffer;
        }

        static winrt::Windows::Storage::Streams::IBuffer ArrayToStorageBuffer(array_view<uint8_t const> bytes)
        {
            winrt::Windows::Storage::Streams::Buffer buffer(bytes.size());
            memcpy(buffer.data(), bytes.data(), bytes.size());
            buffer.Length(bytes.size());
            return buffer;
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct ByteBuffers : ByteBuffersT<ByteBuffers, implementation::ByteBuffers>
    {
    };
}

#include "ByteBuffers.g.cpp"