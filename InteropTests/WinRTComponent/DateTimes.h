#pragma once
#include "DateTimes.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct DateTimes
    {
        DateTimes() = default;

        static winrt::Windows::Foundation::TimeSpan FromSeconds(int32_t seconds);
        static int32_t RoundToSeconds(winrt::Windows::Foundation::TimeSpan const& timeSpan);
        static winrt::Windows::Foundation::DateTime FromUTCYearMonthDay(int32_t year, int32_t month, int32_t day);
        static void ToUTCYearMonthDay(winrt::Windows::Foundation::DateTime const& dateTime, int32_t& year, int32_t& month, int32_t& day);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct DateTimes : DateTimesT<DateTimes, implementation::DateTimes>
    {
    };
}
