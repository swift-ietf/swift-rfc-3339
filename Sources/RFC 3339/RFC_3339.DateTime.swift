public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_3339 {

    public struct DateTime: Sendable, Codable {

        public let time: Time

        public let offset: Offset

        public let precision: Int?

        private init(__unchecked: Void, time: Time, offset: Offset, precision: Int?) {
            self.time = time
            self.offset = offset
            self.precision = precision
        }

        public init(time: Time, offset: Offset = .utc, precision: Int? = nil) {
            self.init(
                __unchecked: (),
                time: time,
                offset: offset,
                precision: precision.map { min(max($0, 0), 9) }
            )
        }
    }
}

extension RFC_3339.DateTime: Hashable {}

extension RFC_3339.DateTime: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        let time = value.time

        appendYear(&buffer, time.year.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.month.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.day.rawValue)

        buffer.append(ASCII.Code.T)

        appendTwoDigits(&buffer, time.hour.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.minute.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.second.value)

        if let precision = value.precision {
            appendFraction(&buffer, time: time, precision: precision)
        } else {
            appendFractionIfNonZero(&buffer, time: time)
        }

        RFC_3339.Offset.serialize(value.offset, into: &buffer)
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ dateTime: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        let time = dateTime.time

        appendYear(&buffer, time.year.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.month.rawValue)
        buffer.append(ASCII.Code.hyphen)
        appendTwoDigits(&buffer, time.day.rawValue)

        buffer.append(ASCII.Code.T)

        appendTwoDigits(&buffer, time.hour.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.minute.value)
        buffer.append(ASCII.Code.colon)
        appendTwoDigits(&buffer, time.second.value)

        if let precision = dateTime.precision {
            appendFraction(&buffer, time: time, precision: precision)
        } else {
            appendFractionIfNonZero(&buffer, time: time)
        }

        RFC_3339.Offset.serialize(dateTime.offset, into: &buffer)
    }
}

extension RFC_3339.DateTime: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        guard bytes.count >= 20 else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        let arr: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            arr = try [ASCII.Code](bytes)
        } catch {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }
        var index = 0

        let year = try Self.parseYear(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.hyphen)
        let month = try Self.parseMonth(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.hyphen)
        let day = try Self.parseDay(arr, index: &index, month: month, year: year)

        try Self.expectEither(arr, index: &index, code1: ASCII.Code.T, code2: ASCII.Code.t)

        let hour = try Self.parseHour(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.colon)
        let minute = try Self.parseMinute(arr, index: &index)
        try Self.expect(arr, index: &index, code: ASCII.Code.colon)
        let second = try Self.parseSecond(arr, index: &index)

        var millisecond = 0
        var microsecond = 0
        var nanosecond = 0

        if index < arr.count && arr[index] == ASCII.Code.period {
            index += 1
            (millisecond, microsecond, nanosecond) = try Self.parseFraction(arr, index: &index)
        }

        let offset = try Self.parseOffset(arr, index: &index)

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

        guard index == arr.count else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

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

extension RFC_3339.DateTime: Swift.RawRepresentable {

    public var rawValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_3339.DateTime: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension Instant {

    public init(_ dateTime: RFC_3339.DateTime) {

        let utcSeconds = dateTime.time.secondsSinceEpoch - dateTime.offset.seconds
        let utcTime = Time(secondsSinceEpoch: utcSeconds)
        self.init(utcTime)
    }
}

extension RFC_3339.DateTime {

    private static var yearDomain: ClosedRange<Int> { 0...9999 }

    private static func appendYear<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ year: Int
    ) where Buffer.Element == Byte {
        let absYear = min(max(year, yearDomain.lowerBound), yearDomain.upperBound)
        if absYear < 10 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 100 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 1000 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(absYear).utf8)
    }

    private static func appendTwoDigits<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ value: Int
    ) where Buffer.Element == Byte {
        if value < 10 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(value).utf8)
    }

    private static func appendFraction<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time,
        precision: Int
    ) where Buffer.Element == Byte {
        guard precision > 0 && precision <= 9 else { return }

        buffer.append(ASCII.Code.period)

        let totalNanos = time.totalNanoseconds

        var divisor = 1
        for _ in 0..<(9 - precision) {
            divisor *= 10
        }
        let truncated = totalNanos / divisor

        var fractionString = String(truncated)

        while fractionString.count < precision {
            fractionString = "0" + fractionString
        }

        buffer.append(contentsOf: fractionString.utf8)
    }

    private static func appendFractionIfNonZero<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time
    ) where Buffer.Element == Byte {
        let totalNanos = time.totalNanoseconds
        guard totalNanos > 0 else { return }

        buffer.append(ASCII.Code.period)

        var fractionString = String(totalNanos)

        while fractionString.count < 9 {
            fractionString = "0" + fractionString
        }

        while fractionString.last == "0" {
            fractionString.removeLast()
        }

        buffer.append(contentsOf: fractionString.utf8)
    }
}

extension RFC_3339.DateTime {

    private static func appendYear<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ year: Int
    ) where Buffer.Element == ASCII.Code {
        let absYear = min(max(year, yearDomain.lowerBound), yearDomain.upperBound)
        if absYear < 10 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 100 {
            buffer.append(contentsOf: [ASCII.Code.`0`, ASCII.Code.`0`])
        } else if absYear < 1000 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(absYear).utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }

    private static func appendTwoDigits<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ value: Int
    ) where Buffer.Element == ASCII.Code {
        if value < 10 {
            buffer.append(ASCII.Code.`0`)
        }
        buffer.append(contentsOf: String(value).utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }

    private static func appendFraction<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time,
        precision: Int
    ) where Buffer.Element == ASCII.Code {
        guard precision > 0 && precision <= 9 else { return }

        buffer.append(ASCII.Code.period)

        let totalNanos = time.totalNanoseconds

        var divisor = 1
        for _ in 0..<(9 - precision) {
            divisor *= 10
        }
        let truncated = totalNanos / divisor

        var fractionString = String(truncated)

        while fractionString.count < precision {
            fractionString = "0" + fractionString
        }

        buffer.append(contentsOf: fractionString.utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }

    private static func appendFractionIfNonZero<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        time: Time
    ) where Buffer.Element == ASCII.Code {
        let totalNanos = time.totalNanoseconds
        guard totalNanos > 0 else { return }

        buffer.append(ASCII.Code.period)

        var fractionString = String(totalNanos)

        while fractionString.count < 9 {
            fractionString = "0" + fractionString
        }

        while fractionString.last == "0" {
            fractionString.removeLast()
        }

        buffer.append(contentsOf: fractionString.utf8.map { ASCII.Code(unchecked: Byte($0)) })
    }
}

extension RFC_3339.DateTime {

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

        let y = Time.Year(year)
        let m: Time.Month
        do throws(Time.Month.Error) {
            m = try Time.Month(month)
        } catch {
            throw Error.invalidDay("\(day) for month \(month), year \(year)")
        }

        do throws(Time.Month.Day.Error) {
            _ = try Time.Month.Day(day, in: m, year: y)
        } catch {
            throw Error.invalidDay("\(day) for month \(month), year \(year)")
        }

        return day
    }

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

    private static func parseFraction(
        _ codes: [ASCII.Code],
        index: inout Int
    ) throws(Error) -> (Int, Int, Int) {
        var fractionString = ""

        while index < codes.count, codes[index].isDigit {
            fractionString.append(Character(codes[index]))
            index += 1
        }

        guard !fractionString.isEmpty else {
            throw Error.invalidFraction("empty fraction")
        }

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

    private static func parseOffset(
        _ codes: [ASCII.Code],
        index: inout Int
    ) throws(Error) -> RFC_3339.Offset {
        guard index < codes.count else {
            throw Error.invalidOffset("missing offset")
        }

        if codes[index] == ASCII.Code.Z || codes[index] == ASCII.Code.z {
            index += 1
            return .utc
        }

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

        if offsetSeconds == 0 {

            if sign == -1 {
                return .unknownLocalOffset
            }

            return .utc
        }

        do throws(RFC_3339.Offset.Error) {
            return try RFC_3339.Offset(seconds: offsetSeconds)
        } catch {
            throw Error.invalidOffset("offset out of range: \(offsetSeconds)")
        }
    }

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

    private static func digitValue(_ code: ASCII.Code) -> Int? {
        code.digitValue.map(Int.init)
    }

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
