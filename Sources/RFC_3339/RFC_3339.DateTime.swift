// RFC_3339.DateTime.swift
// swift-rfc-3339
//
// RFC 3339 Section 5.6: Internet Date/Time Format

extension RFC_3339 {
    /// RFC 3339 date-time value
    ///
    /// Combines a calendar time with a UTC offset to represent a complete
    /// RFC 3339 timestamp.
    ///
    /// ## Structure
    ///
    /// A date-time consists of:
    /// - **time**: Calendar date and time components (``Time``)
    /// - **offset**: UTC timezone offset (``Offset``)
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Create from components
    /// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
    /// let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
    ///
    /// // Format to string
    /// let formatted = RFC_3339.Formatter.format(dateTime)
    /// // "2024-11-22T14:30:00Z"
    ///
    /// // Parse from string
    /// let parsed = try RFC_3339.Parser.parse("1985-04-12T23:20:50.52Z")
    /// print(parsed.time.year)  // 1985
    /// print(parsed.offset)     // .utc
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``Offset``
    /// - ``Parser``
    /// - ``Formatter``
    public struct DateTime: Sendable, Equatable, Hashable {
        /// Calendar time components
        public let time: Time

        /// UTC offset
        public let offset: Offset

        /// Create a date-time from time and offset
        ///
        /// - Parameters:
        ///   - time: Calendar date and time
        ///   - offset: UTC offset (defaults to `.utc`)
        public init(time: Time, offset: Offset = .utc) {
            self.time = time
            self.offset = offset
        }
    }
}

// MARK: - Instant Conversion

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension Instant {
    /// Create instant from RFC 3339 date-time
    ///
    /// Applies the offset to convert the local time to UTC, then creates an instant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
    /// let dt = RFC_3339.DateTime(time: time, offset: .offset(seconds: -28800)) // PST
    ///
    /// let instant = Instant(dt)
    /// // Represents 2024-11-22 22:30:00 UTC
    /// ```
    ///
    /// - Parameter dateTime: RFC 3339 date-time with offset
    public init(_ dateTime: RFC_3339.DateTime) {
        // Convert local time to UTC by subtracting the offset
        let utcSeconds = dateTime.time.secondsSinceEpoch - dateTime.offset.seconds
        let utcTime = Time(secondsSinceEpoch: utcSeconds)
        self.init(utcTime)
    }
}

// MARK: - Codable

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension RFC_3339.DateTime: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = try RFC_3339.Parser.parse(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let string = RFC_3339.Formatter.format(self)
        try container.encode(string)
    }
}
