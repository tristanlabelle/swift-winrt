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
    com_array<uint8_t> ByteBuffers::GetMemoryBufferBytes(winrt::Windows::Foundation::IMemoryBufferReference const& bufferReference)
    {
        auto pointer = bufferReference.data();
        return { pointer, pointer + bufferReference.Capacity() };
    }
}
