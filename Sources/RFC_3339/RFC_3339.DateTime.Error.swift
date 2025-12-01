// RFC_3339.DateTime.Error.swift
// swift-rfc-3339

extension RFC_3339.DateTime {
    /// Errors that can occur during RFC 3339 date-time parsing
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Invalid format - does not match RFC 3339 grammar
        case invalidFormat(_ value: String)

        /// Year component invalid
        case invalidYear(_ value: String)

        /// Month component out of range (1-12)
        case invalidMonth(_ value: String)

        /// Day component invalid for given month/year
        case invalidDay(_ value: String)

        /// Hour component out of range (0-23)
        case invalidHour(_ value: String)

        /// Minute component out of range (0-59)
        case invalidMinute(_ value: String)

        /// Second component out of range (0-60, allowing leap second)
        case invalidSecond(_ value: String)

        /// Fractional seconds invalid
        case invalidFraction(_ value: String)

        /// Timezone offset invalid
        case invalidOffset(_ value: String)

        /// Leap second (60) not on valid date (Jun 30 or Dec 31)
        case invalidLeapSecond(month: Int, day: Int)
    }
}

extension RFC_3339.DateTime.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidFormat(let value):
            return "Invalid RFC 3339 format: '\(value)'"
        case .invalidYear(let value):
            return "Invalid year: '\(value)'"
        case .invalidMonth(let value):
            return "Invalid month: '\(value)' (must be 01-12)"
        case .invalidDay(let value):
            return "Invalid day: '\(value)'"
        case .invalidHour(let value):
            return "Invalid hour: '\(value)' (must be 00-23)"
        case .invalidMinute(let value):
            return "Invalid minute: '\(value)' (must be 00-59)"
        case .invalidSecond(let value):
            return "Invalid second: '\(value)' (must be 00-60)"
        case .invalidFraction(let value):
            return "Invalid fractional seconds: '\(value)'"
        case .invalidOffset(let value):
            return "Invalid timezone offset: '\(value)'"
        case .invalidLeapSecond(let month, let day):
            return
                "Leap second not allowed on month \(month), day \(day) (only June 30 or December 31)"
        }
    }
}
