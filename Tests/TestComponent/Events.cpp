#include "pch.h"
#include "Events.h"
#include "Events.g.cpp"
#include <unordered_map>

namespace
{
    class Implementation : public winrt::implements<Implementation, winrt::TestComponent::IEvent>
    {
    private:
        std::unordered_map<int64_t, winrt::TestComponent::MinimalDelegate> handlers;
        int64_t nextToken = 1;

    public:
        winrt::event_token Event(winrt::TestComponent::MinimalDelegate const& handler)
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

    class Counter : public winrt::implements<Counter, winrt::TestComponent::IEventCounter>
    {
    private:
        winrt::TestComponent::IEvent inner;
        winrt::event_token token;
        int32_t count = 0;

    public:
        Counter(winrt::TestComponent::IEvent inner) : inner(inner)
        {
            token = inner.Event([this]() { count++; });
        }

        ~Counter() { Detach(); }

        int32_t Count() { return count; }

        void Detach()
        {
            inner.Event(token);
            token = {};
        }
    };
}

namespace winrt::TestComponent::implementation
{
    winrt::TestComponent::IEvent Events::Create()
    {
        return winrt::make<Implementation>();
    }
    winrt::TestComponent::IEventCounter Events::CreateCounter(winrt::TestComponent::IEvent const& inner)
    {
        return winrt::make<Counter>(inner);
    }
}
