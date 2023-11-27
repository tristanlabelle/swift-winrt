#include "pch.h"
#include "Events.h"
#include "Events.g.cpp"
#include <unordered_map>

namespace
{
    class Source : public winrt::implements<Source, winrt::WinRTComponent::IEventSource>
    {
    private:
        std::unordered_map<int64_t, winrt::WinRTComponent::MinimalDelegate> handlers;
        int64_t nextToken = 1;

    public:
        winrt::event_token Event(winrt::WinRTComponent::MinimalDelegate const& handler)
        {
            auto token = nextToken++;
            handlers.emplace(token, handler);
            return { token };
        }
        void Event(winrt::event_token const& token) noexcept
        {
            auto it = handlers.find(token.value);
            if (it != handlers.end()) handlers.erase(it);
        }
        void Fire()
        {
            for (auto entry : handlers) entry.second();
        }
    };

    class Counter : public winrt::implements<Counter, winrt::WinRTComponent::IEventCounter>
    {
    private:
        winrt::WinRTComponent::IEventSource source;
        winrt::event_token token;
        int32_t count = 0;

    public:
        Counter(winrt::WinRTComponent::IEventSource source) : source(source)
        {
            token = source.Event([this]() { count++; });
        }

        ~Counter() { Detach(); }

        int32_t Count() { return count; }

        void Detach()
        {
            source.Event(token);
            token = {};
        }
    };
}

namespace winrt::WinRTComponent::implementation
{
    winrt::WinRTComponent::IEventSource Events::CreateSource()
    {
        return winrt::make<Source>();
    }
    winrt::WinRTComponent::IEventCounter Events::CreateCounter(winrt::WinRTComponent::IEventSource const& source)
    {
        return winrt::make<Counter>(source);
    }
}
