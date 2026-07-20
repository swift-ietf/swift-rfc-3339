// RFC_3339.DateTime.swift
// swift-rfc-3339

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_3339 {
    /// RFC 3339 date-time value
    ///
    /// Combines a calendar time with a UTC offset to represent a complete
    /// RFC 3339 timestamp.
    ///
    /// ## RFC 3339 Format
    ///
    /// ```
    /// date-time     = full-date "T" full-time
    /// full-date     = date-fullyear "-" date-month "-" date-mday
    /// full-time     = partial-time time-offset
    /// partial-time  = time-hour ":" time-minute ":" time-second [time-secfrac]
    /// time-offset   = "Z" / time-numoffset
    /// time-numoffset= ("+" / "-") time-hour ":" time-minute
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse from string
    /// let dt = try RFC_3339.DateTime("2024-11-22T14:30:00Z")
    ///
    /// // Create from components
    /// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
    /// let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
    ///
    /// // Format to string
    /// let formatted = String(dateTime)  // "2024-11-22T14:30:00Z"
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``Offset``
    public struct DateTime: Sendable, Codable {
        /// Calendar time components
        public let time: Time

        /// UTC offset
        public let offset: Offset

        /// Optional fractional second precision for serialization
        ///
        /// When nil, uses automatic precision (omits trailing zeros).
        /// When set, serializes with exactly that many fractional digits.
        public let precision: Int?

        /// Creates a date-time WITHOUT validation
        private init(__unchecked: Void, time: Time, offset: Offset, precision: Int?) {
            self.time = time
            self.offset = offset
            self.precision = precision
        }

        /// Creates a date-time from time and offset
        ///
        /// - Parameters:
        ///   - time: Calendar date and time
        ///   - offset: UTC offset (defaults to `.utc`)
        ///   - precision: Optional fractional seconds precision (0-9 digits)
        public init(time: Time, offset: Offset = .utc, precision: Int? = nil) {
            self.init(__unchecked: (), time: time, offset: offset, precision: precision)
        }
    }
}

// MARK: - Hashable

extension RFC_3339.DateTime: Hashable {}

// MARK: - ASCII Serialization

extension RFC_3339.DateTime: ASCII.Serializable, Binary.Serializable {
    /// Own `ASCII.Serializable` verb ([FAM-012]) — the RFC 3339 date-time
    /// (`full-date "T" full-time time-offset`), re-expressing the numeric
    /// date/time formatting (year zero-pad, two-digit fields, fraction-trim)
    /// directly over the `ASCII.Code` substrate and composing the already-re-cut
    /// `Offset` **ASCII** verb for the trailing `time-offset`. Output is
    /// byte-identical to the `Binary.Serializable` witness body (`serializeBytes`).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        let time = value.time

        // full-date: YYYY-MM-DD
        appendYear(&buffer, time.year.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.month.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.day.rawValue)

        // 'T' separator
        buffer.append(ASCII.Code.T)

        // partial-time: HH:MM:SS
        appendTwoDigits(&buffer, time.hour.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.minute.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.second.value)

        // time-secfrac (optional)
        if let precision = value.precision {
            appendFraction(&buffer, time: time, precision: precision)
        } else {
            appendFractionIfNonZero(&buffer, time: time)
        }

        // time-offset — compose the re-cut Offset ASCII verb
        RFC_3339.Offset.serialize(value.offset, into: &buffer)
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable defaults.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    /// Byte-domain serialization body (RFC 3339 date-time).
    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ dateTime: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        let time = dateTime.time

        // full-date: YYYY-MM-DD
        appendYear(&buffer, time.year.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.month.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.day.rawValue)

        // 'T' separator
        buffer.append(ASCII.Code.T)

        // partial-time: HH:MM:SS
        appendTwoDigits(&buffer, time.hour.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.minute.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.second.value)

        // time-secfrac (optional)
        if let precision = dateTime.precision {
            appendFraction(&buffer, time: time, precision: precision)
        } else {
            appendFractionIfNonZero(&buffer, time: time)
        }

        // time-offset
        RFC_3339.Offset.serialize(dateTime.offset, into: &buffer)
    }
}

extension RFC_3339.DateTime: ASCII.Parseable {
    /// Creates a date-time by validating `string`'s UTF-8 bytes as ASCII.
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses an RFC 3339 timestamp from ASCII bytes
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3339.DateTime (structured data)
    ///
    /// String parsing is derived composition:
    /// ```
    /// String → [Byte] (UTF-8) → DateTime
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array<Byte>("2024-11-22T14:30:00Z".utf8)
    /// let dt = try RFC_3339.DateTime(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: ASCII byte representation
    /// - Throws: `Error` if format is invalid
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        // Minimum valid: "YYYY-MM-DDTHH:MM:SSZ" = 20 characters
        guard bytes.count >= 20 else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (RFC 3339 grammar is strict ASCII).
        let arr: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            arr = try [ASCII.Code](bytes)
        } catch {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }
        var index = 0

        // Parse full-date: YYYY-MM-DD
        let year = try Self.parseYear(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.hyphen)
        let month = try Self.parseMonth(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.hyphen)
        let day = try Self.parseDay(arr, index: &index, month: month, year: year)

        // Parse 'T' separator (RFC 3339 allows 'T' or 't')
        try Self.expectEither(arr, index: &index, code1: ASCII.Code.T, code2: ASCII.Code.t)

        // Parse partial-time: HH:MM:SS[.fraction]
        let hour = try Self.parseHour(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.colon)
        let minute = try Self.parseMinute(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.colon)
        let second = try Self.parseSecond(arr, index: &index)

        // Parse optional fractional seconds
        var millisecond = 0
        var microsecond = 0
        var nanosecond = 0

        if index < arr.count && arr[index] == ASCII.Code.period {
            index += 1
            (millisecond, microsecond, nanosecond) = try Self.parseFraction(arr, index: &index)
        }

        // Parse time-offset
        let offset = try Self.parseOffset(arr, index: &index)

        // Validate leap second against the UTC instant (offset-aware)
        if second == 60 {
            try RFC_3339.Validation.validateLeapSecond(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                offsetSeconds: offset.seconds
            )
        }

        // Ensure we consumed the entire string
        guard index == arr.count else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        // Construct Time
        let time: Time
        do throws(Time.Error) {
            time = try Time(
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
        } catch {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        self.init(__unchecked: (), time: time, offset: offset, precision: nil)
    }
}

// MARK: - RawRepresentable & CustomStringConvertible

extension RFC_3339.DateTime: Swift.RawRepresentable {
    /// The date-time's RFC 3339 ASCII serialization as a `String`.
    public var rawValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    public init?(rawValue: String) { try? self.init(rawValue) }
}

extension RFC_3339.DateTime: CustomStringConvertible {
    /// The date-time's RFC 3339 ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

// MARK: - Instant Conversion

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension Instant {
    /// Create instant from RFC 3339 date-time
    ///
    /// Applies the offset to convert the local time to UTC, then creates an instant.
    ///
    /// - Parameter dateTime: RFC 3339 date-time with offset
    public init(_ dateTime: RFC_3339.DateTime) {
        // Convert local time to UTC by subtracting the offset
        let utcSeconds = dateTime.time.secondsSinceEpoch - dateTime.offset.seconds
        let utcTime = Time(secondsSinceEpoch: utcSeconds)
        self.init(utcTime)
    }
}

// MARK: - Formatting Helpers

extension RFC_3339.DateTime {
    /// Append 4-digit year
    private static func appendYear<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ year: Int
    ) where Buffer.Element == Byte {
        let absYear = abs(year)
        if year < 0 {
            buffer.append(ASCII.Code.hyphen)
        }
        if absYear < 10 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 100 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 1000 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(absYear).utf8)
    }

    /// Append 2-digit number with leading zero if needed
    private static func appendTwoDigits<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ value: Int
    ) where Buffer.Element == Byte {
        if value < 10 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(value).utf8)
    }

    /// Append fractional seconds with specified precision
    private static func appendFraction<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time,
        precision: Int
    ) where Buffer.Element == Byte {
        guard precision > 0 && precision <= 9 else { return }

        buffer.append(ASCII.Code.period)

        let totalNanos = time.totalNanoseconds
        // Calculate divisor: 10^(9 - precision)
        var divisor = 1
        for _ in 0..<(9 - precision) {
            divisor *= 10
        }
        let truncated = totalNanos / divisor

        var fractionString = String(truncated)
        // Pad with leading zeros to reach requested precision
        while fractionString.count < precision {
            fractionString = "0" + fractionString
        }

        buffer.append(contentsOf: fractionString.utf8)
    }

    /// Append fractional seconds only if non-zero
    private static func appendFractionIfNonZero<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time
    ) where Buffer.Element == Byte {
        let totalNanos = time.totalNanoseconds
        guard totalNanos > 0 else { return }

        buffer.append(ASCII.Code.period)

        // Format with full precision, then trim trailing zeros
        var fractionString = String(totalNanos)

        // Pad to 9 digits
        while fractionString.count < 9 {
            fractionString = "0" + fractionString
        }

        // Remove trailing zeros
        while fractionString.last == "0" {
            fractionString.removeLast()
        }

        buffer.append(contentsOf: fractionString.utf8)
    }
}

// MARK: - Formatting Helpers (ASCII.Code substrate)

extension RFC_3339.DateTime {
    /// Append 4-digit year (ASCII.Code substrate).
    private static func appendYear<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ year: Int
    ) where Buffer.Element == ASCII.Code {
        let absYear = abs(year)
        if year < 0 {
            buffer.append(ASCII.Code.hyphen)
        }
        if absYear < 10 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 100 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 1000 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(absYear).utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }

    /// Append 2-digit number with leading zero if needed (ASCII.Code substrate).
    private static func appendTwoDigits<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ value: Int
    ) where Buffer.Element == ASCII.Code {
        if value < 10 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(value).utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }

    /// Append fractional seconds with specified precision (ASCII.Code substrate).
    private static func appendFraction<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time,
        precision: Int
    ) where Buffer.Element == ASCII.Code {
        guard precision > 0 && precision <= 9 else { return }

        buffer.append(ASCII.Code.period)

        let totalNanos = time.totalNanoseconds
        // Calculate divisor: 10^(9 - precision)
        var divisor = 1
        for _ in 0..<(9 - precision) {
            divisor *= 10
        }
        let truncated = totalNanos / divisor

        var fractionString = String(truncated)
        // Pad with leading zeros to reach requested precision
        while fractionString.count < precision {
            fractionString = "0" + fractionString
        }

        buffer.append(contentsOf: fractionString.utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }

    /// Append fractional seconds only if non-zero (ASCII.Code substrate).
    private static func appendFractionIfNonZero<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time
    ) where Buffer.Element == ASCII.Code {
        let totalNanos = time.totalNanoseconds
        guard totalNanos > 0 else { return }

        buffer.append(ASCII.Code.period)

        // Format with full precision, then trim trailing zeros
        var fractionString = String(totalNanos)

        // Pad to 9 digits
        while fractionString.count < 9 {
            fractionString = "0" + fractionString
        }

        // Remove trailing zeros
        while fractionString.last == "0" {
            fractionString.removeLast()
        }

        buffer.append(contentsOf: fractionString.utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }
}

// MARK: - Parsing Helpers

extension RFC_3339.DateTime {
    /// Parse 4-digit year
    private static func parseYear(_ codes: [ASCII.Code], index: inout Int) throws(Error) -> Int {
        guard index + 4 <= codes.count else {
            throw Error.invalidYear(String(decoding: codes[index...], as: UTF8.self))
        }

        var year = 0
        for _ in 0..<4 {
            guard let digit = digitValue(codes[index]) else {
                throw Error.invalidYear(String(decoding: codes[index...], as: UTF8.self))
            }
            year = year * 10 + digit
            index += 1
        }

        return year
    }

    /// Parse 2-digit month (01-12)
    private static func parseMonth(_ codes: [ASCII.Code], index: inout Int) throws(Error) -> Int {
        guard index + 2 <= codes.count else {
            throw Error.invalidMonth(String(decoding: codes[index...], as: UTF8.self))
        }

        let month = try parseTwoDigits(codes, index: &index)
        guard month >= 1 && month <= 12 else {
            throw Error.invalidMonth("\(month)")
        }

        return month
    }

    /// Parse 2-digit day (01-31, validated for month)
    private static func parseDay(
        _ codes: [ASCII.Code],
        index: inout Int,
        month: Int,
        year: Int
    ) throws(Error) -> Int {
        guard index + 2 <= codes.count else {
            throw Error.invalidDay(String(decoding: codes[index...], as: UTF8.self))
        }

        let day = try parseTwoDigits(codes, index: &index)

        // Validate day is in valid range for month/year
        let y = Time.Year(year)
        guard let m = try? Time.Month(month),
            (try? Time.Month.Day(day, in: m, year: y)) != nil
        else {
            throw Error.invalidDay("\(day) for month \(month), year \(year)")
        }

        return day
    }

    /// Parse 2-digit hour (00-23)
    private static func parseHour(_ codes: [ASCII.Code], index: inout Int) throws(Error) -> Int {
        guard index + 2 <= codes.count else {
            throw Error.invalidHour(String(decoding: codes[index...], as: UTF8.self))
        }

        let hour = try parseTwoDigits(codes, index: &index)
        guard hour >= 0 && hour <= 23 else {
            throw Error.invalidHour("\(hour)")
        }

        return hour
    }

    /// Parse 2-digit minute (00-59)
    private static func parseMinute(_ codes: [ASCII.Code], index: inout Int) throws(Error) -> Int {
        guard index + 2 <= codes.count else {
            throw Error.invalidMinute(String(decoding: codes[index...], as: UTF8.self))
        }

        let minute = try parseTwoDigits(codes, index: &index)
        guard minute >= 0 && minute <= 59 else {
            throw Error.invalidMinute("\(minute)")
        }

        return minute
    }

    /// Parse 2-digit second (00-60, allowing leap second)
    private static func parseSecond(_ codes: [ASCII.Code], index: inout Int) throws(Error) -> Int {
        guard index + 2 <= codes.count else {
            throw Error.invalidSecond(String(decoding: codes[index...], as: UTF8.self))
        }

        let second = try parseTwoDigits(codes, index: &index)
        guard second >= 0 && second <= 60 else {
            throw Error.invalidSecond("\(second)")
        }

        return second
    }

    /// Parse fractional seconds: .DIGIT+
    /// Returns (millisecond, microsecond, nanosecond)
    private static func parseFraction(
        _ codes: [ASCII.Code],
        index: inout Int
    ) throws(Error) -> (Int, Int, Int) {
        var fractionString = ""

        // Parse all digits
        while index < codes.count, codes[index].isDigit {
            fractionString.append(Character(codes[index]))
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
    private static func parseOffset(
        _ codes: [ASCII.Code],
        index: inout Int
    ) throws(Error) -> RFC_3339.Offset {
        guard index < codes.count else {
            throw Error.invalidOffset("missing offset")
        }

        // Check for 'Z' or 'z' (UTC) - RFC 3339 allows both
        if codes[index] == ASCII.Code.Z || codes[index] == ASCII.Code.z {
            index += 1
            return .utc
        }

        // Parse numeric offset
        guard index + 6 <= codes.count else {
            throw Error.invalidOffset(String(decoding: codes[index...], as: UTF8.self))
        }

        let sign: Int
        if codes[index] == ASCII.Code.plus {
            sign = 1
        } else if codes[index] == ASCII.Code.hyphen {
            sign = -1
        } else {
            throw Error.invalidOffset("expected '+', '-', or 'Z'")
        }
        index += 1

        let offsetHour = try parseTwoDigits(codes, index: &index)
        try expect(codes, index: &index, code: ASCII.Code.colon)
        let offsetMinute = try parseTwoDigits(codes, index: &index)

        guard offsetHour >= 0 && offsetHour <= 23 else {
            throw Error.invalidOffset("hour out of range: \(offsetHour)")
        }
        guard offsetMinute >= 0 && offsetMinute <= 59 else {
            throw Error.invalidOffset("minute out of range: \(offsetMinute)")
        }

        let offsetSeconds = sign * (offsetHour * 3600 + offsetMinute * 60)

        // Special cases for zero offset
        if offsetSeconds == 0 {
            // -00:00 means unknown local offset
            if sign == -1 {
                return .unknownLocalOffset
            }
            // +00:00 means UTC (same as Z)
            return .utc
        }

        do throws(RFC_3339.Offset.Error) {
            return try RFC_3339.Offset(seconds: offsetSeconds)
        } catch {
            throw Error.invalidOffset("offset out of range: \(offsetSeconds)")
        }
    }

    /// Parse exactly 2 digits as integer
    private static func parseTwoDigits(_ codes: [ASCII.Code], index: inout Int) throws(Error) -> Int
    {
        guard index + 2 <= codes.count,
            let d1 = digitValue(codes[index]),
            let d2 = digitValue(codes[index + 1])
        else {
            throw Error.invalidFormat("expected two digits")
        }

        index += 2
        return d1 * 10 + d2
    }

    /// Convert ASCII digit code to numeric value
    private static func digitValue(_ code: ASCII.Code) -> Int? {
        code.digitValue.map(Int.init)
    }

    /// Expect specific code at current index
    private static func expect(
        _ codes: [ASCII.Code],
        index: inout Int,
        code expected: ASCII.Code
    ) throws(Error) {
        guard index < codes.count && codes[index] == expected else {
            throw Error.invalidFormat("expected '\(Character(expected))'")
        }
        index += 1
    }

    /// Expect either of two codes at current index (for case-insensitive parsing)
    private static func expectEither(
        _ codes: [ASCII.Code],
        index: inout Int,
        code1: ASCII.Code,
        code2: ASCII.Code
    ) throws(Error) {
        guard index < codes.count && (codes[index] == code1 || codes[index] == code2) else {
            throw Error.invalidFormat(
                "expected '\(Character(code1))' or '\(Character(code2))'"
            )
        }
        index += 1
    }
}
