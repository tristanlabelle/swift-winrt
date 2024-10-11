#include "pch.h"
#include "DateTimes.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct DateTimes
    {
        static winrt::Windows::Foundation::TimeSpan FromSeconds(int32_t seconds)
        {
            return std::chrono::seconds(seconds);
        }

        static int32_t RoundToSeconds(winrt::Windows::Foundation::TimeSpan const& timeSpan)
        {
            return static_cast<int32_t>(std::chrono::round<std::chrono::seconds>(timeSpan).count());
        }

        static winrt::Windows::Foundation::DateTime FromUTCYearMonthDay(int32_t year, int32_t month, int32_t day)
        {
            tm components = {};
            components.tm_year = year - 1900;
            components.tm_mon = month - 1;
            components.tm_mday = day;
            auto const time = _mkgmtime64(&components);
            if (time == -1) throw winrt::hresult_invalid_argument(L"Invalid date");
            return winrt::clock::from_time_t(time);
        }

        static void ToUTCYearMonthDay(winrt::Windows::Foundation::DateTime const& dateTime, int32_t& year, int32_t& month, int32_t& day)
        {
            auto const time = winrt::clock::to_time_t(dateTime);
            tm components;
            if (_gmtime64_s(&components, &time) != 0) throw winrt::hresult_invalid_argument(L"Failed to convert to a date");
            year = components.tm_year + 1900;
            month = components.tm_mon + 1;
            day = components.tm_mday;
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct DateTimes : DateTimesT<DateTimes, implementation::DateTimes>
    {
    };
}

#include "DateTimes.g.cpp"