extension RFC_3339.DateTime {

    public enum Error: Swift::Error, Sendable, Equatable {

        case invalidFormat(_ value: String)

        case invalidYear(_ value: String)

        case invalidMonth(_ value: String)

        case invalidDay(_ value: String)

        case invalidHour(_ value: String)

        case invalidMinute(_ value: String)

        case invalidSecond(_ value: String)

        case invalidFraction(_ value: String)

        case invalidOffset(_ value: String)

        case unsupportedLeapSecond(_ value: String)
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
            return "Invalid second: '\(value)' (must be 00-59)"

        case .invalidFraction(let value):
            return "Invalid fractional seconds: '\(value)'"

        case .invalidOffset(let value):
            return "Invalid timezone offset: '\(value)'"

        case .unsupportedLeapSecond(let value):
            return "Unsupported leap second: '\(value)' (days are a uniform 86,400 seconds, so the second must be 00-59)"
        }
    }
}
