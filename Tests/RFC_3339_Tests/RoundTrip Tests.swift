// RoundTrip Tests.swift
// swift-rfc-3339
//
// Comprehensive round-trip conversion tests
// Parse → Format → Parse cycles should preserve semantics

import Testing
@testable import RFC_3339

@Suite("RFC 3339 - Round-trip Conversions")
struct RoundTripTests {
    @Test("Round-trip: parse then format")
    func roundTrip() throws {
        let original = "1985-04-12T23:20:50.52Z"
        let dt = try RFC_3339.Parser.parse(original)
        let formatted = RFC_3339.Formatter.format(dt)

        // Parse again to compare
        let dt2 = try RFC_3339.Parser.parse(formatted)

        #expect(dt.time.year == dt2.time.year)
        #expect(dt.time.month == dt2.time.month)
        #expect(dt.time.day == dt2.time.day)
        #expect(dt.time.hour == dt2.time.hour)
        #expect(dt.time.minute == dt2.time.minute)
        #expect(dt.time.second == dt2.time.second)
        #expect(dt.offset == dt2.offset)
    }

    @Test(arguments: [
        "2024-11-22T14:30:00Z",
        "1985-04-12T23:20:50.52Z",
        "1996-12-19T16:39:57-08:00",
        "1990-12-31T23:59:60Z",
        "2024-01-01T00:00:00-00:00",
        "2024-11-22T14:30:00+05:30",
        "0000-01-01T00:00:00Z",
        "9999-12-31T23:59:59Z",
        "2015-06-30T23:59:60Z"
    ])
    func roundTripVariousTimestamps(timestamp: String) throws {
        let dt = try RFC_3339.Parser.parse(timestamp)
        let formatted = RFC_3339.Formatter.format(dt)
        let dt2 = try RFC_3339.Parser.parse(formatted)

        // Verify semantic equality (not string equality, as formatter may normalize)
        #expect(dt.time.year == dt2.time.year)
        #expect(dt.time.month == dt2.time.month)
        #expect(dt.time.day == dt2.time.day)
        #expect(dt.time.hour == dt2.time.hour)
        #expect(dt.time.minute == dt2.time.minute)
        #expect(dt.time.second == dt2.time.second)
        #expect(dt.time.millisecond == dt2.time.millisecond)
        #expect(dt.time.microsecond == dt2.time.microsecond)
        #expect(dt.time.nanosecond == dt2.time.nanosecond)
        #expect(dt.offset == dt2.offset)
    }

    @Test("Round-trip with different case")
    func roundTripDifferentCase() throws {
        // Input has lowercase, output will have uppercase
        let input = "2024-11-22t14:30:00z"
        let dt = try RFC_3339.Parser.parse(input)
        let formatted = RFC_3339.Formatter.format(dt)

        // Should normalize to uppercase
        #expect(formatted == "2024-11-22T14:30:00Z")

        // But parse back should be identical
        let dt2 = try RFC_3339.Parser.parse(formatted)
        #expect(dt.time.year == dt2.time.year)
        #expect(dt.offset == dt2.offset)
    }

    @Test("Round-trip +00:00 normalizes to Z")
    func roundTripPlusZeroZero() throws {
        let input = "2024-11-22T14:30:00+00:00"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.offset == .utc)

        let formatted = RFC_3339.Formatter.format(dt)

        // Should normalize to Z (preferred form)
        #expect(formatted == "2024-11-22T14:30:00Z")

        let dt2 = try RFC_3339.Parser.parse(formatted)
        #expect(dt.offset == dt2.offset)
    }

    @Test("Round-trip preserves unknown local offset")
    func roundTripUnknownLocalOffset() throws {
        let input = "2024-11-22T14:30:00-00:00"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.offset == .unknownLocalOffset)

        let formatted = RFC_3339.Formatter.format(dt)

        // Should preserve -00:00 (not Z)
        #expect(formatted == "2024-11-22T14:30:00-00:00")

        let dt2 = try RFC_3339.Parser.parse(formatted)
        #expect(dt.offset == dt2.offset)
        #expect(dt2.offset == .unknownLocalOffset)
    }

    @Test("Round-trip with fractional seconds")
    func roundTripFractionalSeconds() throws {
        let testCases = [
            "2024-01-01T00:00:00.1Z",
            "2024-01-01T00:00:00.12Z",
            "2024-01-01T00:00:00.123Z",
            "2024-01-01T00:00:00.123456Z",
            "2024-01-01T00:00:00.123456789Z"
        ]

        for input in testCases {
            let dt = try RFC_3339.Parser.parse(input)
            let formatted = RFC_3339.Formatter.format(dt)
            let dt2 = try RFC_3339.Parser.parse(formatted)

            #expect(dt.time.millisecond == dt2.time.millisecond)
            #expect(dt.time.microsecond == dt2.time.microsecond)
            #expect(dt.time.nanosecond == dt2.time.nanosecond)
        }
    }

    @Test("Round-trip format with explicit precision")
    func roundTripWithExplicitPrecision() throws {
        let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0, millisecond: 123)
        let dateTime = RFC_3339.DateTime(time: time, offset: .utc)

        // Format with specific precision
        let formatted = RFC_3339.Formatter.format(dateTime, precision: 6)
        #expect(formatted == "2024-01-01T00:00:00.123000Z")

        // Parse back
        let dt2 = try RFC_3339.Parser.parse(formatted)

        #expect(dt2.time.millisecond.value == 123)
        #expect(dt2.time.microsecond.value == 0)
        #expect(dt2.time.nanosecond.value == 0)
    }
}
