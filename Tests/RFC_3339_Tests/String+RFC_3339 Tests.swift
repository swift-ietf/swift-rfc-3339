// String+RFC_3339 Tests.swift
// swift-rfc-3339
//
// Tests for String and Time extensions

import Testing
@testable import RFC_3339

// MARK: - String Extension Tests

@Suite("String+RFC_3339 - Parsing")
struct StringExtensionParseTests {
    @Test("String extension: parse")
    func stringExtensionParse() throws {
        let timestamp = "2024-11-22T14:30:00Z"
        let dt = try timestamp.rfc3339.parse()

        #expect(dt.time.year.value == 2024)
    }

    @Test("String extension: parse with offset")
    func parseWithOffset() throws {
        let timestamp = "2024-11-22T14:30:00-08:00"
        let dt = try timestamp.rfc3339.parse()

        #expect(dt.offset == .offset(seconds: -28800))
    }

    @Test("String extension: parse with fractional seconds")
    func parseWithFractionalSeconds() throws {
        let timestamp = "1985-04-12T23:20:50.52Z"
        let dt = try timestamp.rfc3339.parse()

        #expect(dt.time.millisecond.value == 520)
    }
}

@Suite("String+RFC_3339 - Validation")
struct StringExtensionValidationTests {
    @Test("String extension: isValid for valid timestamp")
    func isValidForValidTimestamp() {
        #expect("2024-11-22T14:30:00Z".rfc3339.isValid)
    }

    @Test("String extension: isValid for invalid timestamp")
    func isValidForInvalidTimestamp() {
        #expect(!"invalid".rfc3339.isValid)
    }

    @Test("String extension: isValid for missing separator")
    func isValidForMissingSeparator() {
        #expect(!"2024-11-22 14:30:00".rfc3339.isValid) // missing T
    }

    @Test("String extension: isValid for various formats")
    func isValidForVariousFormats() {
        let validTimestamps = [
            "2024-11-22T14:30:00Z",
            "2024-11-22t14:30:00z",
            "2024-11-22T14:30:00+00:00",
            "2024-11-22T14:30:00-00:00",
            "2024-11-22T14:30:00+05:30",
            "1985-04-12T23:20:50.52Z",
            "1990-12-31T23:59:60Z"
        ]

        for timestamp in validTimestamps {
            #expect(timestamp.rfc3339.isValid, "Should be valid: \(timestamp)")
        }
    }

    @Test("String extension: isValid for various invalid formats")
    func isValidForInvalidFormats() {
        let invalidTimestamps = [
            "",
            "not a timestamp",
            "2024-11-22",
            "14:30:00",
            "2024-11-22 14:30:00Z",  // space instead of T
            "2024-11-22T14:30:00",    // missing offset
            "24-11-22T14:30:00Z",     // 2-digit year
            "2024-13-01T00:00:00Z",   // invalid month
            "2024-02-30T00:00:00Z",   // invalid day
            "2024-01-01T25:00:00Z"    // invalid hour
        ]

        for timestamp in invalidTimestamps {
            #expect(!timestamp.rfc3339.isValid, "Should be invalid: \(timestamp)")
        }
    }
}

// MARK: - Time Extension Tests

@Suite("Time+RFC_3339 - Formatting")
struct TimeExtensionFormatTests {
    @Test("Time extension: format with default UTC")
    func timeExtensionFormat() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = time.rfc3339.format()

        #expect(formatted == "2024-11-22T14:30:00Z")
    }

    @Test("Time extension: format with explicit offset")
    func formatWithExplicitOffset() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = time.rfc3339.format(offset: .offset(seconds: -28800))

        #expect(formatted == "2024-11-22T14:30:00-08:00")
    }

    @Test("Time extension: format with precision")
    func formatWithPrecision() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = time.rfc3339.format(precision: 3)

        #expect(formatted == "2024-11-22T14:30:00.000Z")
    }

    @Test("Time extension: format with offset and precision")
    func formatWithOffsetAndPrecision() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0, millisecond: 123)
        let formatted = time.rfc3339.format(offset: .offset(seconds: 19800), precision: 3)

        #expect(formatted == "2024-11-22T14:30:00.123+05:30")
    }

    @Test("Time extension: format with fractional seconds")
    func formatWithFractionalSeconds() throws {
        let time = try Time(year: 1985, month: 4, day: 12, hour: 23, minute: 20, second: 50, millisecond: 520)
        let formatted = time.rfc3339.format()

        #expect(formatted == "1985-04-12T23:20:50.52Z")
    }
}

// MARK: - Integration Tests

@Suite("String+RFC_3339 - Integration with Time")
struct StringTimeIntegrationTests {
    @Test("Round-trip via extensions")
    func roundTripViaExtensions() throws {
        let original = "2024-11-22T14:30:00.123Z"
        let dt = try original.rfc3339.parse()
        let formatted = dt.time.rfc3339.format(offset: dt.offset)
        let dt2 = try formatted.rfc3339.parse()

        #expect(dt.time.year == dt2.time.year)
        #expect(dt.time.month == dt2.time.month)
        #expect(dt.time.day == dt2.time.day)
        #expect(dt.time.millisecond == dt2.time.millisecond)
        #expect(dt.offset == dt2.offset)
    }

    @Test("Validate then parse")
    func validateThenParse() throws {
        let timestamp = "2024-11-22T14:30:00Z"

        #expect(timestamp.rfc3339.isValid)

        let dt = try timestamp.rfc3339.parse()
        #expect(dt.time.year.value == 2024)
    }

    @Test("Format then validate")
    func formatThenValidate() throws {
        let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
        let formatted = time.rfc3339.format()

        #expect(formatted.rfc3339.isValid)
    }
}
