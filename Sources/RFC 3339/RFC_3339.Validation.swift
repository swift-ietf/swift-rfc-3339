// RFC_3339.Validation.swift
// swift-rfc-3339

extension RFC_3339 {
    /// RFC 3339 validation rules
    ///
    /// Validates constraints specified in RFC 3339, particularly leap second handling.
    ///
    /// ## Leap Seconds
    ///
    /// Per RFC 3339 Section 5.7:
    /// > "Leap seconds cannot be predicted far in advance due to the unpredictable rate
    /// > of the rotation of the earth. Leap seconds have been historically added on
    /// > June 30 or December 31."
    ///
    /// This implementation validates that second=60 only appears when the
    /// timestamp's UTC instant (local components adjusted by the numeric
    /// offset) is 23:59:60 on June 30 or December 31, following historical
    /// practice.
    ///
    /// ## See Also
    ///
    /// - ``DateTime``
    public enum Validation {}
}

// MARK: - Leap Second Validation

extension RFC_3339.Validation {
    /// Validate a leap second against its UTC instant
    ///
    /// Ensures that second=60 (leap second) only occurs at a UTC instant of
    /// 23:59:60 on June 30 or December 31 (historical insertion practice).
    /// The local date/time components are converted to UTC using the parsed
    /// numeric offset before the rule is applied, so valid east- and
    /// west-offset leap seconds (e.g. RFC 3339 Section 5.8's
    /// `1990-12-31T15:59:60-08:00`) are accepted, and locally-plausible but
    /// impossible instants (e.g. `1990-12-31T12:00:60Z`) are rejected.
    ///
    /// - Parameters:
    ///   - year: Local year value
    ///   - month: Local month value (1-12)
    ///   - day: Local day value (1-31)
    ///   - hour: Local hour value (0-23)
    ///   - minute: Local minute value (0-59)
    ///   - offsetSeconds: UTC offset in seconds (multiple of 60, |offset| < 24h)
    /// - Throws: ``RFC_3339.DateTime.Error/invalidLeapSecond(month:day:)``
    ///   (carrying the UTC month/day) if the instant is not a valid leap second
    public static func validateLeapSecond(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        offsetSeconds: Int
    ) throws(RFC_3339.DateTime.Error) {
        // Convert local wall-clock components to UTC. RFC 3339 offsets are
        // strictly less than 24 hours, so the date shifts by at most one day.
        var utcYear = year
        var utcMonth = month
        var utcDay = day
        var minutesOfDay = hour * 60 + minute - offsetSeconds / 60

        if minutesOfDay < 0 {
            minutesOfDay += 24 * 60
            utcDay -= 1
            if utcDay < 1 {
                utcMonth -= 1
                if utcMonth < 1 {
                    utcMonth = 12
                    utcYear -= 1
                }
                utcDay = daysIn(month: utcMonth, year: utcYear)
            }
        } else if minutesOfDay >= 24 * 60 {
            minutesOfDay -= 24 * 60
            utcDay += 1
            if utcDay > daysIn(month: utcMonth, year: utcYear) {
                utcDay = 1
                utcMonth += 1
                if utcMonth > 12 {
                    utcMonth = 1
                    utcYear += 1
                }
            }
        }

        let utcHour = minutesOfDay / 60
        let utcMinute = minutesOfDay % 60

        let isLeapSecondInstant =
            utcHour == 23 && utcMinute == 59
            && ((utcMonth == 6 && utcDay == 30) || (utcMonth == 12 && utcDay == 31))

        guard isLeapSecondInstant else {
            throw RFC_3339.DateTime.Error.invalidLeapSecond(month: utcMonth, day: utcDay)
        }
    }

    /// Number of days in a Gregorian month
    private static func daysIn(month: Int, year: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        default:
            let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
            return isLeap ? 29 : 28
        }
    }
}
