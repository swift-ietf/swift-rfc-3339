// Parser Tests.swift
// swift-rfc-3339
//
// Comprehensive tests for RFC_3339.DateTime parsing

import Testing

@testable import RFC_3339

// MARK: - Basic Parsing

@Suite("RFC_3339.DateTime - UTC Timestamps")
struct ParserUTCTests {
    @Test
    func `Parse simple UTC timestamp`() throws {
        let input = "2024-11-22T14:30:00Z"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.year == 2024)
        #expect(dt.time.month == 11)
        #expect(dt.time.day == 22)
        #expect(dt.time.hour.value == 14)
        #expect(dt.time.minute.value == 30)
        #expect(dt.time.second.value == 0)
        #expect(dt.offset == .utc)
    }

    @Test
    func `Parse lowercase 'z' offset`() throws {
        let input = "2024-11-22T14:30:00z"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.year == 2024)
        #expect(dt.offset == .utc)
    }

    @Test
    func `Parse +00:00 as UTC`() throws {
        let input = "2024-11-22T14:30:00+00:00"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.offset == .utc)
        #expect(dt.offset.seconds == 0)
    }

    @Test
    func `Z and +00:00 are semantically identical`() throws {
        let withZ = try RFC_3339.DateTime("2024-11-22T14:30:00Z")
        let withPlus = try RFC_3339.DateTime("2024-11-22T14:30:00+00:00")

        #expect(withZ.offset == withPlus.offset)
        #expect(withZ.offset == .utc)
        #expect(withPlus.offset == .utc)
    }
}

@Suite("RFC_3339.DateTime - Numeric Offsets")
struct ParserNumericOffsetTests {
    @Test
    func `Parse timestamp with positive offset`() throws {
        let input = "2024-11-22T14:30:00+05:30"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.year == 2024)
        #expect(dt.offset == .offset(seconds: 19800))  // 5.5 hours
    }

    @Test
    func `Parse timestamp with negative offset`() throws {
        let input = "2024-11-22T14:30:00-08:00"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.year == 2024)
        #expect(dt.offset == .offset(seconds: -28800))  // -8 hours
    }

    @Test
    func `Parse unknown local offset`() throws {
        let input = "2024-11-22T14:30:00-00:00"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.offset == .unknownLocalOffset)
    }
}

@Suite("RFC_3339.DateTime - Fractional Seconds")
struct ParserFractionalSecondsTests {
    @Test
    func `Parse timestamp with fractional seconds`() throws {
        let input = "1985-04-12T23:20:50.52Z"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.year == 1985)
        #expect(dt.time.millisecond.value == 520)
        #expect(dt.offset == .utc)
    }

    @Test
    func `Parse various fractional second precisions`() throws {
        let inputs = [
            ("2024-01-01T00:00:00.1Z", 100),  // 1 digit
            ("2024-01-01T00:00:00.12Z", 120),  // 2 digits
            ("2024-01-01T00:00:00.123Z", 123),  // 3 digits
            ("2024-01-01T00:00:00.1234Z", 123),  // 4 digits (truncated)
            ("2024-01-01T00:00:00.123456789Z", 123),  // 9 digits (truncated)
        ]

        for (input, expectedMillis) in inputs {
            let dt = try RFC_3339.DateTime(input)
            #expect(dt.time.millisecond.value == expectedMillis)
        }
    }
}

@Suite("RFC_3339.DateTime - Leap Seconds")
struct ParserLeapSecondTests {
    @Test
    func `Parse leap second`() throws {
        let input = "1990-12-31T23:59:60Z"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.second.value == 60)
        #expect(dt.time.month == 12)
        #expect(dt.time.day == 31)
    }

    @Test
    func `Leap second on June 30`() throws {
        let input = "2015-06-30T23:59:60Z"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.second.value == 60)
        #expect(dt.time.month == 6)
        #expect(dt.time.day == 30)
    }
}

@Suite("RFC_3339.DateTime - Case Insensitivity")
struct ParserCaseInsensitivityTests {
    @Test
    func `Parse lowercase 't' separator`() throws {
        let input = "2024-11-22t14:30:00Z"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.year == 2024)
        #expect(dt.time.hour.value == 14)
        #expect(dt.offset == .utc)
    }

    @Test
    func `Parse lowercase 't' and 'z'`() throws {
        let input = "2024-11-22t14:30:00z"
        let dt = try RFC_3339.DateTime(input)

        #expect(dt.time.year == 2024)
        #expect(dt.offset == .utc)
    }
}

@Suite("RFC_3339.DateTime - StringProtocol Support")
struct ParserStringProtocolTests {
    @Test
    func `Parse substring`() throws {
        let full = "timestamp: 2024-11-22T14:30:00Z end"
        let substring = full.dropFirst(11).dropLast(4)  // Extract just the timestamp

        let dt = try RFC_3339.DateTime(String(substring))

        #expect(dt.time.year == 2024)
        #expect(dt.time.month == 11)
        #expect(dt.time.day == 22)
        #expect(dt.offset == .utc)
    }
}
