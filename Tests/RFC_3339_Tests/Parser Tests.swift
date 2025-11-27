// Parser Tests.swift
// swift-rfc-3339
//
// Comprehensive tests for RFC_3339.Parser

import Testing

@testable import RFC_3339

// MARK: - Basic Parsing

@Suite("RFC_3339.Parser - UTC Timestamps")
struct ParserUTCTests {
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

    @Test("Parse lowercase 'z' offset")
    func parseLowercaseZ() throws {
        let input = "2024-11-22T14:30:00z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.offset == .utc)
    }

    @Test("Parse +00:00 as UTC")
    func parsePlusZeroZero() throws {
        let input = "2024-11-22T14:30:00+00:00"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.offset == .utc)
        #expect(dt.offset.seconds == 0)
    }

    @Test("Z and +00:00 are semantically identical")
    func zAndPlusZeroZeroIdentical() throws {
        let withZ = try RFC_3339.Parser.parse("2024-11-22T14:30:00Z")
        let withPlus = try RFC_3339.Parser.parse("2024-11-22T14:30:00+00:00")

        #expect(withZ.offset == withPlus.offset)
        #expect(withZ.offset == .utc)
        #expect(withPlus.offset == .utc)
    }
}

@Suite("RFC_3339.Parser - Numeric Offsets")
struct ParserNumericOffsetTests {
    @Test("Parse timestamp with positive offset")
    func parsePositiveOffset() throws {
        let input = "2024-11-22T14:30:00+05:30"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.offset == .offset(seconds: 19800))  // 5.5 hours
    }

    @Test("Parse timestamp with negative offset")
    func parseNegativeOffset() throws {
        let input = "2024-11-22T14:30:00-08:00"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.offset == .offset(seconds: -28800))  // -8 hours
    }

    @Test("Parse unknown local offset")
    func parseUnknownLocalOffset() throws {
        let input = "2024-11-22T14:30:00-00:00"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.offset == .unknownLocalOffset)
    }
}

@Suite("RFC_3339.Parser - Fractional Seconds")
struct ParserFractionalSecondsTests {
    @Test("Parse timestamp with fractional seconds")
    func parseFractionalSeconds() throws {
        let input = "1985-04-12T23:20:50.52Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 1985)
        #expect(dt.time.millisecond.value == 520)
        #expect(dt.offset == .utc)
    }

    @Test("Parse various fractional second precisions")
    func parseVariousPrecisions() throws {
        let inputs = [
            ("2024-01-01T00:00:00.1Z", 100),  // 1 digit
            ("2024-01-01T00:00:00.12Z", 120),  // 2 digits
            ("2024-01-01T00:00:00.123Z", 123),  // 3 digits
            ("2024-01-01T00:00:00.1234Z", 123),  // 4 digits (truncated)
            ("2024-01-01T00:00:00.123456789Z", 123),  // 9 digits (truncated)
        ]

        for (input, expectedMillis) in inputs {
            let dt = try RFC_3339.Parser.parse(input)
            #expect(dt.time.millisecond.value == expectedMillis)
        }
    }
}

@Suite("RFC_3339.Parser - Leap Seconds")
struct ParserLeapSecondTests {
    @Test("Parse leap second")
    func parseLeapSecond() throws {
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
}

@Suite("RFC_3339.Parser - Case Insensitivity")
struct ParserCaseInsensitivityTests {
    @Test("Parse lowercase 't' separator")
    func parseLowercaseT() throws {
        let input = "2024-11-22t14:30:00Z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.time.hour.value == 14)
        #expect(dt.offset == .utc)
    }

    @Test("Parse lowercase 't' and 'z'")
    func parseLowercaseTAndZ() throws {
        let input = "2024-11-22t14:30:00z"
        let dt = try RFC_3339.Parser.parse(input)

        #expect(dt.time.year.value == 2024)
        #expect(dt.offset == .utc)
    }
}

@Suite("RFC_3339.Parser - StringProtocol Support")
struct ParserStringProtocolTests {
    @Test("Parse substring")
    func parseSubstring() throws {
        let full = "timestamp: 2024-11-22T14:30:00Z end"
        let substring = full.dropFirst(11).dropLast(4)  // Extract just the timestamp

        let dt = try RFC_3339.Parser.parse(substring)

        #expect(dt.time.year.value == 2024)
        #expect(dt.time.month.value == 11)
        #expect(dt.time.day.value == 22)
        #expect(dt.offset == .utc)
    }
}
