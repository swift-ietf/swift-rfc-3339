// BasicTests.swift
// swift-rfc-3339
//
// Basic RFC 3339 functionality tests

import Testing
@testable import RFC_3339

@Suite("RFC 3339 Basic Tests")
struct BasicTests {

    @Test("Parse simple UTC timestamp")
    func parseSimpleUTC() throws {
        let input = "2024-11-22T14:30:00Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.time.month.value == 11)
        #expect(dt.time.day.value == 22)
        #expect(dt.time.hour.value == 14)
        #expect(dt.time.minute.value == 30)
        #expect(dt.time.second.value == 0)
        #expect(dt.offset == .utc)
    }

    @Test("Parse timestamp with positive offset")
    func parsePositiveOffset() throws {
        let input = "2024-11-22T14:30:00+05:30"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.offset == .offset(seconds: 19800)) // 5.5 hours
    }

    @Test("Parse timestamp with negative offset")
    func parseNegativeOffset() throws {
        let input = "2024-11-22T14:30:00-08:00"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.offset == .offset(seconds: -28800)) // -8 hours
    }

    @Test("Parse timestamp with fractional seconds")
    func parseFractionalSeconds() throws {
        let input = "1985-04-12T23:20:50.52Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 1985)
        #expect(dt.time.millisecond.value == 520)
        #expect(dt.offset == .utc)
    }

    @Test("Parse unknown local offset")
    func parseUnknownLocalOffset() throws {
        let input = "2024-11-22T14:30:00-00:00"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.offset == .unknownLocalOffset)
    }

    @Test("Parse leap second")
    func parseLeapSecond() throws {
        let input = "1990-12-31T23:59:60Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.second.value == 60)
        #expect(dt.time.month.value == 12)
        #expect(dt.time.day.value == 31)
    }

    @Test("Format simple UTC timestamp")
    func formatSimpleUTC() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc)

        #expect(formatted == "2024-11-22T14:30:00Z")
    }

    @Test("Format with offset")
    func formatWithOffset() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .offset(seconds: -28800))

        #expect(formatted == "2024-11-22T14:30:00-08:00")
    }

    @Test("Format with precision")
    func formatWithPrecision() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .utc, precision: 3)

        #expect(formatted == "2024-11-22T14:30:00.000Z")
    }

    @Test("Format unknown local offset")
    func formatUnknownLocalOffset() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = RFC_3339.Formatter.format(time, offset: .unknownLocalOffset)

        #expect(formatted == "2024-11-22T14:30:00-00:00")
    }

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

    @Test("String extension: parse")
    func stringExtensionParse() throws {
        let timestamp = "2024-11-22T14:30:00Z"
        let dt = try timestamp.rfc3339.parse()

        #expect(dt.time.year.value == 2024)
    }

    @Test("String extension: isValid")
    func stringExtensionIsValid() {
        #expect("2024-11-22T14:30:00Z".rfc3339.isValid)
        #expect(!"invalid".rfc3339.isValid)
        #expect(!"2024-11-22 14:30:00".rfc3339.isValid) // missing T
    }

    @Test("Time extension: format")
    func timeExtensionFormat() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = time.rfc3339.format()

        #expect(formatted == "2024-11-22T14:30:00Z")
    }
}
