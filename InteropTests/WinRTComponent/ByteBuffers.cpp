#include "pch.h"
#include "ByteBuffers.h"
#include "ByteBuffers.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::Windows::Foundation::IMemoryBuffer ByteBuffers::CreateMemoryBuffer(array_view<uint8_t const> data)
    {
        winrt::Windows::Foundation::MemoryBuffer buffer(data.size());
        auto reference = buffer.CreateReference();
        memcpy(reference.data(), data.data(), data.size());
        return buffer;
    }
    com_array<uint8_t> ByteBuffers::GetMemoryBufferReferenceBytes(winrt::Windows::Foundation::IMemoryBufferReference const& reference)
    {
        auto pointer = reference.data();
        return { pointer, pointer + reference.Capacity() };
    }
    winrt::Windows::Storage::Streams::IBuffer ByteBuffers::CreateBuffer(array_view<uint8_t const> data)
    {
        winrt::Windows::Storage::Streams::Buffer buffer(data.size());
        memcpy(buffer.data(), data.data(), data.size());
        return buffer;
    }
    com_array<uint8_t> ByteBuffers::GetBufferBytes(winrt::Windows::Storage::Streams::IBuffer const& buffer)
    {
        auto pointer = buffer.data();
        return { pointer, pointer + buffer.Length() };
    }
}
