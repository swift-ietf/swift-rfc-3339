// RFC_3339.Parser.swift
// swift-rfc-3339
//
// RFC 3339 Section 5.6: Internet Date/Time Format - Parsing

extension RFC_3339 {
    /// RFC 3339 timestamp parser
    ///
    /// Parses RFC 3339 formatted strings into ``DateTime`` values.
    ///
    /// ## Grammar
    ///
    /// ```
    /// date-time     = full-date "T" full-time
    /// full-date     = date-fullyear "-" date-month "-" date-mday
    /// full-time     = partial-time time-offset
    /// partial-time  = time-hour ":" time-minute ":" time-second [time-secfrac]
    /// time-secfrac  = "." 1*DIGIT
    /// time-offset   = "Z" / time-numoffset
    /// time-numoffset= ("+" / "-") time-hour ":" time-minute
    /// ```
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // UTC time
    /// let dt1 = try RFC_3339.Parser.parse("1985-04-12T23:20:50.52Z")
    ///
    /// // With numeric offset
    /// let dt2 = try RFC_3339.Parser.parse("1996-12-19T16:39:57-08:00")
    ///
    /// // Leap second
    /// let dt3 = try RFC_3339.Parser.parse("1990-12-31T23:59:60Z")
    ///
    /// // Unknown local offset
    /// let dt4 = try RFC_3339.Parser.parse("2024-01-01T00:00:00-00:00")
    /// // dt4.offset == .unknownLocalOffset
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``DateTime``
    /// - ``Formatter``
    public enum Parser {}
}

// MARK: - Error

extension RFC_3339.Parser {
    /// Parsing errors
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Invalid format - does not match RFC 3339 grammar
        case invalidFormat(String)

        /// Year component invalid
        case invalidYear(String)

        /// Month component out of range (1-12)
        case invalidMonth(String)

        /// Day component invalid for given month/year
        case invalidDay(String)

        /// Hour component out of range (0-23)
        case invalidHour(String)

        /// Minute component out of range (0-59)
        case invalidMinute(String)

        /// Second component out of range (0-60, allowing leap second)
        case invalidSecond(String)

        /// Fractional seconds invalid
        case invalidFraction(String)

        /// Timezone offset invalid
        case invalidOffset(String)

        /// Leap second (60) not on valid date (Jun 30 or Dec 31)
        case invalidLeapSecond(month: Int, day: Int)
    }
}

// MARK: - Parse

extension RFC_3339.Parser {
    /// Parse RFC 3339 timestamp string
    ///
    /// Validates format and creates a ``DateTime`` value.
    ///
    /// - Parameter string: RFC 3339 formatted timestamp
    /// - Returns: Parsed date-time
    /// - Throws: ``Error`` if format is invalid or components out of range
    public static func parse(_ string: some StringProtocol) throws -> RFC_3339.DateTime {
        // Minimum valid: "YYYY-MM-DDTHH:MM:SSZ" = 20 characters
        guard string.count >= 20 else {
            throw Error.invalidFormat(String(string))
        }

        let bytes = Array(string.utf8)
        var index = 0

        // Parse full-date: YYYY-MM-DD
        guard index + 10 <= bytes.count else {
            throw Error.invalidFormat(String(string))
        }

        let year = try parseYear(bytes, index: &index)
        try expect(bytes, index: &index, byte: UInt8(ascii: "-"))
        let month = try parseMonth(bytes, index: &index)
        try expect(bytes, index: &index, byte: UInt8(ascii: "-"))
        let day = try parseDay(bytes, index: &index, month: month, year: year)

        // Parse 'T' separator
        try expect(bytes, index: &index, byte: UInt8(ascii: "T"))

        // Parse partial-time: HH:MM:SS[.fraction]
        let hour = try parseHour(bytes, index: &index)
        try expect(bytes, index: &index, byte: UInt8(ascii: ":"))
        let minute = try parseMinute(bytes, index: &index)
        try expect(bytes, index: &index, byte: UInt8(ascii: ":"))
        let second = try parseSecond(bytes, index: &index)

        // Validate leap second
        if second == 60 {
            try RFC_3339.Validation.validateLeapSecond(month: month, day: day)
        }

        // Parse optional fractional seconds
        var millisecond = 0
        var microsecond = 0
        var nanosecond = 0

        if index < bytes.count && bytes[index] == UInt8(ascii: ".") {
            index += 1
            (millisecond, microsecond, nanosecond) = try parseFraction(bytes, index: &index)
        }

        // Parse time-offset
        let offset = try parseOffset(bytes, index: &index)

        // Ensure we consumed the entire string
        guard index == bytes.count else {
            throw Error.invalidFormat(String(string))
        }

        // Construct Time
        let time = try Time(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            millisecond: millisecond,
            microsecond: microsecond,
            nanosecond: nanosecond
        )

        return RFC_3339.DateTime(time: time, offset: offset)
    }
}

// MARK: - Component Parsing

extension RFC_3339.Parser {
    /// Parse 4-digit year
    private static func parseYear(_ bytes: [UInt8], index: inout Int) throws -> Int {
        guard index + 4 <= bytes.count else {
            throw Error.invalidYear(String(decoding: bytes[index...], as: UTF8.self))
        }

        var year = 0
        for _ in 0..<4 {
            guard let digit = digitValue(bytes[index]) else {
                throw Error.invalidYear(String(decoding: bytes[index...], as: UTF8.self))
            }
            year = year * 10 + digit
            index += 1
        }

        return year
    }

    /// Parse 2-digit month (01-12)
    private static func parseMonth(_ bytes: [UInt8], index: inout Int) throws -> Int {
        guard index + 2 <= bytes.count else {
            throw Error.invalidMonth(String(decoding: bytes[index...], as: UTF8.self))
        }

        let month = try parseTwoDigits(bytes, index: &index)
        guard month >= 1 && month <= 12 else {
            throw Error.invalidMonth("\(month)")
        }

        return month
    }

    /// Parse 2-digit day (01-31, validated for month)
    private static func parseDay(_ bytes: [UInt8], index: inout Int, month: Int, year: Int) throws -> Int {
        guard index + 2 <= bytes.count else {
            throw Error.invalidDay(String(decoding: bytes[index...], as: UTF8.self))
        }

        let day = try parseTwoDigits(bytes, index: &index)

        // Validate day is in valid range for month/year
        let y = Time.Year(year)
        guard let m = try? Time.Month(month),
              (try? Time.Month.Day(day, in: m, year: y)) != nil else {
            throw Error.invalidDay("\(day) for month \(month), year \(year)")
        }

        return day
    }

    /// Parse 2-digit hour (00-23)
    private static func parseHour(_ bytes: [UInt8], index: inout Int) throws -> Int {
        guard index + 2 <= bytes.count else {
            throw Error.invalidHour(String(decoding: bytes[index...], as: UTF8.self))
        }

        let hour = try parseTwoDigits(bytes, index: &index)
        guard hour >= 0 && hour <= 23 else {
            throw Error.invalidHour("\(hour)")
        }

        return hour
    }

    /// Parse 2-digit minute (00-59)
    private static func parseMinute(_ bytes: [UInt8], index: inout Int) throws -> Int {
        guard index + 2 <= bytes.count else {
            throw Error.invalidMinute(String(decoding: bytes[index...], as: UTF8.self))
        }

        let minute = try parseTwoDigits(bytes, index: &index)
        guard minute >= 0 && minute <= 59 else {
            throw Error.invalidMinute("\(minute)")
        }

        return minute
    }

    /// Parse 2-digit second (00-60, allowing leap second)
    private static func parseSecond(_ bytes: [UInt8], index: inout Int) throws -> Int {
        guard index + 2 <= bytes.count else {
            throw Error.invalidSecond(String(decoding: bytes[index...], as: UTF8.self))
        }

        let second = try parseTwoDigits(bytes, index: &index)
        guard second >= 0 && second <= 60 else {
            throw Error.invalidSecond("\(second)")
        }

        return second
    }

    /// Parse fractional seconds: .DIGIT+
    /// Returns (millisecond, microsecond, nanosecond)
    private static func parseFraction(_ bytes: [UInt8], index: inout Int) throws -> (Int, Int, Int) {
        var fractionString = ""

        // Parse all digits
        while index < bytes.count, let digit = digitValue(bytes[index]) {
            fractionString.append(Character(UnicodeScalar(UInt32(UInt8(ascii: "0")) + UInt32(digit))!))
            index += 1
        }

        guard !fractionString.isEmpty else {
            throw Error.invalidFraction("empty fraction")
        }

        // Pad or truncate to 9 digits (nanosecond precision)
        var paddedFraction = fractionString
        while paddedFraction.count < 9 {
            paddedFraction.append("0")
        }
        paddedFraction = String(paddedFraction.prefix(9))
        guard let totalNanos = Int(paddedFraction) else {
            throw Error.invalidFraction(fractionString)
        }

        let millisecond = totalNanos / 1_000_000
        let microsecond = (totalNanos % 1_000_000) / 1_000
        let nanosecond = totalNanos % 1_000

        return (millisecond, microsecond, nanosecond)
    }

    /// Parse time offset: Z | (+|-)HH:MM
    private static func parseOffset(_ bytes: [UInt8], index: inout Int) throws -> RFC_3339.Offset {
        guard index < bytes.count else {
            throw Error.invalidOffset("missing offset")
        }

        // Check for 'Z' (UTC)
        if bytes[index] == UInt8(ascii: "Z") {
            index += 1
            return .utc
        }

        // Parse numeric offset
        guard index + 6 <= bytes.count else {
            throw Error.invalidOffset(String(decoding: bytes[index...], as: UTF8.self))
        }

        let sign: Int
        if bytes[index] == UInt8(ascii: "+") {
            sign = 1
        } else if bytes[index] == UInt8(ascii: "-") {
            sign = -1
        } else {
            throw Error.invalidOffset("expected '+', '-', or 'Z'")
        }
        index += 1

        let offsetHour = try parseTwoDigits(bytes, index: &index)
        try expect(bytes, index: &index, byte: UInt8(ascii: ":"))
        let offsetMinute = try parseTwoDigits(bytes, index: &index)

        guard offsetHour >= 0 && offsetHour <= 23 else {
            throw Error.invalidOffset("hour out of range: \(offsetHour)")
        }
        guard offsetMinute >= 0 && offsetMinute <= 59 else {
            throw Error.invalidOffset("minute out of range: \(offsetMinute)")
        }

        let offsetSeconds = sign * (offsetHour * 3600 + offsetMinute * 60)

        // Special case: -00:00 means unknown local offset
        if sign == -1 && offsetSeconds == 0 {
            return .unknownLocalOffset
        }

        return try RFC_3339.Offset(seconds: offsetSeconds)
    }
}

// MARK: - Utility Functions

extension RFC_3339.Parser {
    /// Parse exactly 2 digits as integer
    private static func parseTwoDigits(_ bytes: [UInt8], index: inout Int) throws -> Int {
        guard index + 2 <= bytes.count,
              let d1 = digitValue(bytes[index]),
              let d2 = digitValue(bytes[index + 1]) else {
            throw Error.invalidFormat("expected two digits")
        }

        index += 2
        return d1 * 10 + d2
    }

    /// Convert ASCII digit byte to numeric value
    private static func digitValue(_ byte: UInt8) -> Int? {
        guard byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9") else {
            return nil
        }
        return Int(byte - UInt8(ascii: "0"))
    }

    /// Expect specific byte at current index
    private static func expect(_ bytes: [UInt8], index: inout Int, byte expected: UInt8) throws {
        guard index < bytes.count && bytes[index] == expected else {
            throw Error.invalidFormat("expected '\(Character(UnicodeScalar(expected)))'")
        }
        index += 1
    }
}
