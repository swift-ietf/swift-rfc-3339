// Formatter Tests.swift
// swift-rfc-3339
//
// Comprehensive tests for RFC_3339.Formatter

import Testing
@testable import RFC_3339

// MARK: - Basic Formatting

@Suite("RFC_3339.Formatter - UTC Formatting")
struct FormatterUTCTests {
    @Test("Format simple UTC timestamp")
    func formatSimpleUTC() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted == "2024-11-22T14:30:00Z")
    }

    @Test("Format UTC uses 'Z' not '+00:00'")
    func formatUTCUsesZ() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted.hasSuffix("Z"))
        #expect(!formatted.contains("+00:00"))
    }
}

@Suite("RFC_3339.Formatter - Numeric Offsets")
struct FormatterNumericOffsetTests {
    @Test("Format with positive offset")
    func formatWithPositiveOffset() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .offset(seconds: 19800))

        #expect(formatted == "2024-11-22T14:30:00+05:30")
    }

    @Test("Format with negative offset")
    func formatWithNegativeOffset() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .offset(seconds: -28800))

        #expect(formatted == "2024-11-22T14:30:00-08:00")
    }

    @Test("Format unknown local offset")
    func formatUnknownLocalOffset() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .unknownLocalOffset)

        #expect(formatted == "2024-11-22T14:30:00-00:00")
    }

    @Test("Format various timezone offsets")
    func formatVariousOffsets() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)

        let testCases: [(seconds: Int, expected: String)] = [
            (-43200, "2024-01-01T00:00:00-12:00"),  // UTC-12
            (-28800, "2024-01-01T00:00:00-08:00"),  // PST
            (-18000, "2024-01-01T00:00:00-05:00"),  // EST
            (3600, "2024-01-01T00:00:00+01:00"),    // CET
            (19800, "2024-01-01T00:00:00+05:30"),   // IST
            (32400, "2024-01-01T00:00:00+09:00"),   // JST
            (43200, "2024-01-01T00:00:00+12:00")    // UTC+12
        ]

        for (seconds, expected) in testCases {
            let formatted = RFC_3339.Formatter.format(time, offset: .offset(seconds: seconds))
            #expect(formatted == expected)
        }
    }
}

@Suite("RFC_3339.Formatter - Fractional Seconds")
struct FormatterFractionalSecondsTests {
    @Test("Format with millisecond precision")
    func formatWithPrecision() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc, precision: 3)

        #expect(formatted == "2024-11-22T14:30:00.000Z")
    }

    @Test("Format with various precisions")
    func formatVariousPrecisions() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0, millisecond: 123, microsecond: 456, nanosecond: 789)

        let testCases: [(precision: Int, expected: String)] = [
            (0, "2024-01-01T00:00:00Z"),
            (1, "2024-01-01T00:00:00.1Z"),
            (2, "2024-01-01T00:00:00.12Z"),
            (3, "2024-01-01T00:00:00.123Z"),
            (6, "2024-01-01T00:00:00.123456Z"),
            (9, "2024-01-01T00:00:00.123456789Z")
        ]

        for (precision, expected) in testCases {
            let formatted = RFC_3339.Formatter.format(time, offset: .utc, precision: precision)
            #expect(formatted == expected)
        }
    }

    @Test("Format without precision omits zero fractional seconds")
    func formatOmitsZeroFraction() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted == "2024-01-01T00:00:00Z")
        #expect(!formatted.contains("."))
    }

    @Test("Format without precision includes non-zero fractional seconds")
    func formatIncludesNonZeroFraction() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0, millisecond: 123)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted == "2024-01-01T00:00:00.123Z")
    }
}

@Suite("RFC_3339.Formatter - DateTime Formatting")
struct FormatterDateTimeTests {
    @Test("Format DateTime directly")
    func formatDateTime() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
        let formatted = RFC_3339.Formatter.format(dateTime)

        #expect(formatted == "2024-11-22T14:30:00Z")
    }

    @Test("Format DateTime with precision")
    func formatDateTimeWithPrecision() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0, millisecond: 123)
        let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
        let formatted = RFC_3339.Formatter.format(dateTime, precision: 3)

        #expect(formatted == "2024-11-22T14:30:00.123Z")
    }
}
