public import ASCII_Serializer
public import Binary_Serializable
public import Parseable_ASCII

extension RFC_3339 {

    public enum Offset: Sendable, Equatable, Hashable, Codable {

        case utc

        case unknownLocalOffset

        case offset(seconds: Int)
    }
}

extension RFC_3339.Offset {

    public var seconds: Int {
        switch self {
        case .utc, .unknownLocalOffset:
            return 0

        case .offset(let seconds):
            return seconds
        }
    }

    public var isUTC: Bool {
        seconds == 0
    }
}

extension RFC_3339.Offset {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case invalidFormat(_ value: String)

        case offsetOutOfRange(_ seconds: Int)
    }

    public init(seconds: Int) throws(Error) {
        let maxOffset = 23 * 3600 + 59 * 60
        guard seconds >= -maxOffset && seconds <= maxOffset else {
            throw Error.offsetOutOfRange(seconds)
        }

        if seconds == 0 {
            self = .utc
        } else {
            self = .offset(seconds: seconds)
        }
    }
}

extension RFC_3339.Offset.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Offset cannot be empty"

        case .invalidFormat(let value):
            return "Invalid offset format: '\(value)'"

        case .offsetOutOfRange(let seconds):
            return "Offset \(seconds) seconds is out of range (±23:59)"
        }
    }
}

extension RFC_3339.Offset: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        switch value {
        case .utc:
            buffer.append(ASCII.Code.Z)

        case .unknownLocalOffset:
            buffer.append(contentsOf: "-00:00".utf8.map { ASCII.Code(unchecked: Byte($0)) })

        case .offset(let seconds):

            let clamped = min(max(seconds, -Self.maxOffsetSeconds), Self.maxOffsetSeconds)
            let sign: ASCII.Code = clamped >= 0 ? .plus : .hyphen
            let absSeconds = abs(clamped)
            let hours = absSeconds / 3600
            let minutes = (absSeconds % 3600) / 60

            buffer.append(sign)
            appendTwoDigits(&buffer, hours)
            buffer.append(ASCII.Code.colon)
            appendTwoDigits(&buffer, minutes)
        }
    }

    private static var maxOffsetSeconds: Int { 23 * 3600 + 59 * 60 }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ offset: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        switch offset {
        case .utc:
            buffer.append(ASCII.Code.Z)

        case .unknownLocalOffset:
            buffer.append(contentsOf: "-00:00".utf8)

        case .offset(let seconds):

            let clamped = min(max(seconds, -maxOffsetSeconds), maxOffsetSeconds)
            let sign: ASCII.Code = clamped >= 0 ? .plus : .hyphen
            let absSeconds = abs(clamped)
            let hours = absSeconds / 3600
            let minutes = (absSeconds % 3600) / 60

            buffer.append(sign)
            appendTwoDigits(&buffer, hours)
            buffer.append(ASCII.Code.colon)
            appendTwoDigits(&buffer, minutes)
        }
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
}

extension RFC_3339.Offset: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        let arr: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            arr = try [ASCII.Code](bytes)
        } catch {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        if arr.count == 1 && (arr[0] == ASCII.Code.Z || arr[0] == ASCII.Code.z) {
            self = .utc
            return
        }

        guard arr.count >= 6 else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        let sign: Int
        if arr[0] == ASCII.Code.plus {
            sign = 1
        } else if arr[0] == ASCII.Code.hyphen {
            sign = -1
        } else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        guard let h1 = Self.digitValue(arr[1]),
            let h2 = Self.digitValue(arr[2]),
            arr[3] == ASCII.Code.colon,
            let m1 = Self.digitValue(arr[4]),
            let m2 = Self.digitValue(arr[5])
        else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        let hours = h1 * 10 + h2
        let minutes = m1 * 10 + m2

        guard hours <= 23 && minutes <= 59 else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        let offsetSeconds = sign * (hours * 3600 + minutes * 60)

        if offsetSeconds == 0 {
            if sign == -1 {
                self = .unknownLocalOffset
            } else {
                self = .utc
            }
            return
        }

        let maxOffset = 23 * 3600 + 59 * 60
        guard offsetSeconds >= -maxOffset && offsetSeconds <= maxOffset else {
            throw Error.offsetOutOfRange(offsetSeconds)
        }

        self = .offset(seconds: offsetSeconds)
    }

    private static func digitValue(_ code: ASCII.Code) -> Int? {
        code.digitValue.map(Int.init)
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
}

extension RFC_3339.Offset: Swift.RawRepresentable {

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

extension RFC_3339.Offset: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}
