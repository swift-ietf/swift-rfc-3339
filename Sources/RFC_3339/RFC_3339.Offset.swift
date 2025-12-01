// RFC_3339.Offset.swift
// swift-rfc-3339

public import INCITS_4_1986

extension RFC_3339 {
    /// UTC offset for RFC 3339 timestamps
    ///
    /// Represents the timezone offset component of an RFC 3339 date-time.
    ///
    /// ## Semantic Distinctions
    ///
    /// RFC 3339 Section 4.3 defines important semantic differences:
    ///
    /// - **UTC (Z or +00:00)**: The time is in UTC and UTC is the preferred reference point.
    ///   Both "Z" and "+00:00" are treated identically and map to `.utc`.
    /// - **Unknown local offset (-00:00)**: The time is in UTC but the offset to local time is unknown.
    ///   The string "-00:00" specifically indicates this semantic difference.
    /// - **Numeric offset**: The time is in a specific timezone relative to UTC.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse from string
    /// let offset = try RFC_3339.Offset("+05:30")
    ///
    /// // Serialize to string
    /// let formatted = String(RFC_3339.Offset.utc)  // "Z"
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``DateTime``
    public enum Offset: Sendable, Equatable, Hashable, Codable {
        /// UTC time with zero local offset
        ///
        /// Formats as "Z" in compact form or "+00:00" in numeric form.
        /// Indicates the generating system is in UTC.
        case utc

        /// UTC time with unknown local offset
        ///
        /// Formats as "-00:00". Per RFC 3339 Section 4.3:
        /// "If the time in UTC is known, but the offset to local time is unknown,
        /// this can be represented with an offset of '-00:00'."
        case unknownLocalOffset

        /// Numeric timezone offset in seconds
        ///
        /// - Parameter seconds: Offset from UTC in seconds, positive for east, negative for west
        case offset(seconds: Int)
    }
}

// MARK: - Computed Properties

extension RFC_3339.Offset {
    /// Offset in seconds from UTC
    ///
    /// Both `.utc` and `.unknownLocalOffset` return 0, as they both represent UTC time.
    public var seconds: Int {
        switch self {
        case .utc, .unknownLocalOffset:
            return 0
        case .offset(let seconds):
            return seconds
        }
    }

    /// Whether this offset represents UTC time
    ///
    /// Returns true for both `.utc` and `.unknownLocalOffset`, as both represent
    /// instants at UTC, regardless of semantic distinction.
    public var isUTC: Bool {
        seconds == 0
    }
}

// MARK: - Validation

extension RFC_3339.Offset {
    /// Error conditions for offset validation
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Input is empty
        case empty

        /// Invalid format
        case invalidFormat(_ value: String)

        /// Offset seconds out of valid range (-86340 to +86340, i.e., -23:59 to +23:59)
        case offsetOutOfRange(_ seconds: Int)
    }

    /// Create offset from seconds with validation
    ///
    /// Validates that the offset is within RFC 3339 allowed range of ±23:59.
    ///
    /// - Parameter seconds: Offset in seconds from UTC
    /// - Returns: Validated offset
    /// - Throws: ``Error/offsetOutOfRange(_:)`` if seconds is outside valid range
    public init(seconds: Int) throws {
        let maxOffset = 23 * 3600 + 59 * 60  // 23:59 = 86340 seconds
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

// MARK: - UInt8.ASCII.Serializable

extension RFC_3339.Offset: UInt8.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii offset: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        switch offset {
        case .utc:
            buffer.append(UInt8.ascii.Z)

        case .unknownLocalOffset:
            buffer.append(contentsOf: "-00:00".utf8)

        case .offset(let seconds):
            let sign = seconds >= 0 ? UInt8.ascii.plus : UInt8.ascii.hyphen
            let absSeconds = abs(seconds)
            let hours = absSeconds / 3600
            let minutes = (absSeconds % 3600) / 60

            buffer.append(sign)
            appendTwoDigits(&buffer, hours)
            buffer.append(UInt8.ascii.colon)
            appendTwoDigits(&buffer, minutes)
        }
    }

    /// Parses an RFC 3339 offset from ASCII bytes
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_3339.Offset (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("+05:30".utf8)
    /// let offset = try RFC_3339.Offset(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: ASCII byte representation
    /// - Throws: `Error` if format is invalid
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        let arr = Array(bytes)

        // Check for 'Z' or 'z' (UTC)
        if arr.count == 1 && (arr[0] == UInt8.ascii.Z || arr[0] == UInt8.ascii.z) {
            self = .utc
            return
        }

        // Parse numeric offset: (+|-)HH:MM
        guard arr.count >= 6 else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        let sign: Int
        if arr[0] == UInt8.ascii.plus {
            sign = 1
        } else if arr[0] == UInt8.ascii.hyphen {
            sign = -1
        } else {
            throw Error.invalidFormat(String(decoding: bytes, as: UTF8.self))
        }

        guard let h1 = Self.digitValue(arr[1]),
              let h2 = Self.digitValue(arr[2]),
              arr[3] == UInt8.ascii.colon,
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

        // Special cases for zero offset
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

    /// Convert ASCII digit byte to numeric value
    private static func digitValue(_ byte: UInt8) -> Int? {
        guard byte >= UInt8.ascii.`0` && byte <= UInt8.ascii.`9` else {
            return nil
        }
        return Int(byte - UInt8.ascii.`0`)
    }

    /// Append 2-digit number with leading zero if needed
    private static func appendTwoDigits<Buffer: RangeReplaceableCollection>(
        _ buffer: inout Buffer,
        _ value: Int
    ) where Buffer.Element == UInt8 {
        if value < 10 {
            buffer.append(UInt8.ascii.`0`)
        }
        buffer.append(contentsOf: String(value).utf8)
    }
}

// MARK: - RawRepresentable & CustomStringConvertible

extension RFC_3339.Offset: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_3339.Offset: CustomStringConvertible {}
