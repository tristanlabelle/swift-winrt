#include "pch.h"
#include "ByteBuffers.h"
#include "ByteBuffers.g.cpp"
#include <winrt/Windows.Storage.Streams.h>

namespace winrt::WinRTComponent::implementation
{
    com_array<uint8_t> ByteBuffers::MemoryBufferToArray(winrt::Windows::Foundation::IMemoryBuffer const& buffer)
    {
        auto bufferReference = buffer.CreateReference();
        auto data = bufferReference.data();
        return { data, data + bufferReference.Capacity() };
    }
    com_array<uint8_t> ByteBuffers::StorageBufferToArray(winrt::Windows::Storage::Streams::IBuffer const& buffer)
    {
        auto data = buffer.data();
        return { data, data + buffer.Length() };
    }
    winrt::Windows::Foundation::IMemoryBuffer ByteBuffers::ArrayToMemoryBuffer(array_view<uint8_t const> bytes)
    {
        winrt::Windows::Foundation::MemoryBuffer buffer(bytes.size());
        memcpy(buffer.CreateReference().data(), bytes.data(), bytes.size());
        return buffer;
    }
    winrt::Windows::Storage::Streams::IBuffer ByteBuffers::ArrayToStorageBuffer(array_view<uint8_t const> bytes)
    {
        winrt::Windows::Storage::Streams::Buffer buffer(bytes.size());
        memcpy(buffer.data(), bytes.data(), bytes.size());
        buffer.Length(bytes.size());
        return buffer;
    }
}
