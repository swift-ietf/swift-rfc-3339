// EdgeCases Tests.swift
// swift-rfc-3339
//
// Edge case tests for RFC 3339 implementation
// Tests boundary conditions and special cases per RFC 3339

import Testing

@testable import RFC_3339

// MARK: - Year Range Edge Cases

@Suite("RFC 3339 - Year Boundaries")
struct YearBoundaryTests {
    @Test("Parse year 0000 (minimum allowed)")
    func parseYear0000() throws {
        let input = "0000-01-01T00:00:00Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 0)
        #expect(dt.time.month.value == 1)
        #expect(dt.time.day.value == 1)
    }

    @Test("Parse year 9999 (maximum allowed)")
    func parseYear9999() throws {
        let input = "9999-12-31T23:59:59Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 9999)
        #expect(dt.time.month.value == 12)
        #expect(dt.time.day.value == 31)
    }

    @Test("Format year 0000")
    func formatYear0000() throws {
        let time = try Time(year: 0, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted == "0000-01-01T00:00:00Z")
    }

    @Test("Format year 9999")
    func formatYear9999() throws {
        let time = try Time(year: 9999, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted == "9999-12-31T23:59:59Z")
    }
}

// MARK: - Leap Second Edge Cases

@Suite("RFC 3339 - Leap Seconds")
struct LeapSecondTests {
    @Test("Leap second on December 31")
    func leapSecondDecember() throws {
        let input = "1990-12-31T23:59:60Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.second.value == 60)
        #expect(dt.time.month.value == 12)
        #expect(dt.time.day.value == 31)
    }

    @Test("Leap second on June 30")
    func leapSecondJune() throws {
        let input = "2015-06-30T23:59:60Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.second.value == 60)
        #expect(dt.time.month.value == 6)
        #expect(dt.time.day.value == 30)
    }

    @Test("Negative leap second (second=58)")
    func negativeLeapSecond() throws {
        // While RFC 3339 grammar allows second=58 for negative leap seconds,
        // they have never occurred in practice. Our implementation allows them
        // but doesn't special-case validate them like positive leap seconds.
        let input = "2024-06-30T23:59:58Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.second.value == 58)
        // Should parse successfully - second=58 is valid per grammar
    }

    @Test("Format leap second")
    func formatLeapSecond() throws {
        let time = try Time(year: 2015, month: 6, day: 30, hour: 23, minute: 59, second: 60)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted == "2015-06-30T23:59:60Z")
    }
}

// MARK: - Offset Edge Cases

@Suite("RFC 3339 - Offset Boundaries")
struct OffsetBoundaryTests {
    @Test("Maximum positive offset (+23:59)")
    func maxPositiveOffset() throws {
        let input = "2024-01-01T00:00:00+23:59"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.offset == .offset(seconds: 86340))  // 23*3600 + 59*60
    }

    @Test("Maximum negative offset (-23:59)")
    func maxNegativeOffset() throws {
        let input = "2024-01-01T00:00:00-23:59"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.offset == .offset(seconds: -86340))
    }

    @Test("Format maximum positive offset")
    func formatMaxPositiveOffset() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .offset(seconds: 86340))

        #expect(formatted == "2024-01-01T00:00:00+23:59")
    }

    @Test("Format maximum negative offset")
    func formatMaxNegativeOffset() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .offset(seconds: -86340))

        #expect(formatted == "2024-01-01T00:00:00-23:59")
    }

    @Test("Zero offset edge cases")
    func zeroOffsetVariations() throws {
        // All three zero offset representations
        let z = try RFC_3339.Parser.parse("2024-01-01T00:00:00Z")
        let plus = try RFC_3339.Parser.parse("2024-01-01T00:00:00+00:00")
        let minus = try RFC_3339.Parser.parse("2024-01-01T00:00:00-00:00")

        #expect(z.offset == .utc)
        #expect(plus.offset == .utc)
        #expect(minus.offset == .unknownLocalOffset)

        // All have zero seconds
        #expect(z.offset.seconds == 0)
        #expect(plus.offset.seconds == 0)
        #expect(minus.offset.seconds == 0)

        // But different semantic meaning
        #expect(z.offset.isUTC)
        #expect(plus.offset.isUTC)
        #expect(minus.offset.isUTC)
    }
}

// MARK: - Fractional Second Edge Cases

@Suite("RFC 3339 - Fractional Second Boundaries")
struct FractionalSecondEdgeCaseTests {
    @Test("Single digit fractional second")
    func singleDigitFraction() throws {
        let input = "2024-01-01T00:00:00.1Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.millisecond.value == 100)
    }

    @Test("Maximum precision (9 digits)")
    func maxPrecisionFraction() throws {
        let input = "2024-01-01T00:00:00.123456789Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.millisecond.value == 123)
        #expect(dt.time.microsecond.value == 456)
        #expect(dt.time.nanosecond.value == 789)
    }

    @Test("More than 9 digits truncates")
    func exceedMaxPrecision() throws {
        let input = "2024-01-01T00:00:00.1234567890123Z"
        let dt = try RFC_3339.Parser.parse(input)

        // Should truncate to first 9 digits
        #expect(dt.time.millisecond.value == 123)
        #expect(dt.time.microsecond.value == 456)
        #expect(dt.time.nanosecond.value == 789)
    }

    @Test("Format precision 0 omits decimal point")
    func formatPrecisionZero() throws {
        let time = try Time(
            year: 2024,
            month: 1,
            day: 1,
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 123
        )
        let formatted = RFC_3339.Formatter.format(time, offset: .utc, precision: 0)

        #expect(formatted == "2024-01-01T00:00:00Z")
        #expect(!formatted.contains("."))
    }

    @Test("Format precision 9 (nanoseconds)")
    func formatPrecisionNine() throws {
        let time = try Time(
            year: 2024,
            month: 1,
            day: 1,
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 1,
            microsecond: 2,
            nanosecond: 3
        )
        let formatted = RFC_3339.Formatter.format(time, offset: .utc, precision: 9)

        #expect(formatted == "2024-01-01T00:00:00.001002003Z")
    }
}

// MARK: - Date/Time Component Boundaries

@Suite("RFC 3339 - Component Boundaries")
struct ComponentBoundaryTests {
    @Test("Midnight (start of day)")
    func midnight() throws {
        let input = "2024-01-01T00:00:00Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.hour.value == 0)
        #expect(dt.time.minute.value == 0)
        #expect(dt.time.second.value == 0)
    }

    @Test("End of day (just before midnight)")
    func endOfDay() throws {
        let input = "2024-01-01T23:59:59Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.hour.value == 23)
        #expect(dt.time.minute.value == 59)
        #expect(dt.time.second.value == 59)
    }

    @Test("First day of year")
    func firstDayOfYear() throws {
        let input = "2024-01-01T00:00:00Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.month.value == 1)
        #expect(dt.time.day.value == 1)
    }

    @Test("Last day of year")
    func lastDayOfYear() throws {
        let input = "2024-12-31T23:59:59Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.month.value == 12)
        #expect(dt.time.day.value == 31)
    }

    @Test("Leap year February 29")
    func leapYearFeb29() throws {
        let input = "2024-02-29T12:00:00Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.time.month.value == 2)
        #expect(dt.time.day.value == 29)
    }
}
