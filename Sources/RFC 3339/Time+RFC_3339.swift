// Time+RFC_3339.swift
// swift-rfc-3339

extension RFC_3339 {
    /// RFC 3339 wrapper for Time
    ///
    /// Provides RFC 3339 formatting operations on Time values.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
    ///
    /// // Format as UTC
    /// let utc = time.rfc3339.format()
    /// // "2024-11-22T14:30:00Z"
    ///
    /// // Format with offset
    /// let pst = time.rfc3339.format(offset: .offset(seconds: -28800))
    /// // "2024-11-22T14:30:00-08:00"
    ///
    /// // Format with precision
    /// let precise = time.rfc3339.format(precision: 3)
    /// // "2024-11-22T14:30:00.000Z"
    /// ```
    public struct TimeWrapper {
        public let value: Time

        internal init(_ value: Time) {
            self.value = value
        }
    }
}

// MARK: - Time Extension

extension Time {
    /// Access RFC 3339 operations for this time
    ///
    /// Provides a namespace for RFC 3339 formatting and operations.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
    /// let formatted = time.rfc3339.format()
    /// // "2024-11-22T14:30:00Z"
    /// ```
    public var rfc3339: RFC_3339.TimeWrapper {
        RFC_3339.TimeWrapper(self)
    }
}

// MARK: - Formatting

extension RFC_3339.TimeWrapper {
    /// Format time as RFC 3339 string
    ///
    /// - Parameters:
    ///   - offset: UTC offset (defaults to `.utc`)
    ///   - precision: Optional fractional seconds precision (0-9 digits)
    /// - Returns: RFC 3339 formatted string
    ///
    /// ## Examples
    ///
    /// ```swift
    /// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
    ///
    /// time.rfc3339.format()
    /// // "2024-11-22T14:30:00Z"
    ///
    /// time.rfc3339.format(offset: .offset(seconds: -18000))
    /// // "2024-11-22T14:30:00-05:00"
    ///
    /// time.rfc3339.format(precision: 6)
    /// // "2024-11-22T14:30:00.000000Z"
    /// ```
    public func format(offset: RFC_3339.Offset = .utc, precision: Int? = nil) -> String {
        let dateTime = RFC_3339.DateTime(time: value, offset: offset, precision: precision)
        return String(dateTime)
    }
}
