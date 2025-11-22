// RFC_3339.Validation.swift
// swift-rfc-3339
//
// RFC 3339 Section 5.7: Restrictions - Leap second validation

extension RFC_3339 {
    /// RFC 3339 validation rules
    ///
    /// Validates constraints specified in RFC 3339, particularly leap second handling.
    ///
    /// ## Leap Seconds
    ///
    /// Per RFC 3339 Section 5.7:
    /// > "Leap seconds cannot be predicted far in advance due to the unpredictable rate
    /// > of the rotation of the earth. Leap seconds have been historically added on
    /// > June 30 or December 31."
    ///
    /// This implementation validates that second=60 only appears on June 30 or December 31,
    /// following historical practice.
    ///
    /// ## See Also
    ///
    /// - ``Parser``
    /// - ``DateTime``
    public enum Validation {}
}

// MARK: - Leap Second Validation

extension RFC_3339.Validation {
    /// Validate leap second date
    ///
    /// Ensures that second=60 (leap second) only occurs on valid dates.
    /// Per historical practice, leap seconds are only inserted on:
    /// - June 30 (month 6, day 30)
    /// - December 31 (month 12, day 31)
    ///
    /// - Parameters:
    ///   - month: Month value (1-12)
    ///   - day: Day value (1-31)
    /// - Throws: ``RFC_3339.Parser.Error/invalidLeapSecond(month:day:)`` if not a valid leap second date
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Valid leap second dates
    /// try RFC_3339.Validation.validateLeapSecond(month: 6, day: 30)  // June 30
    /// try RFC_3339.Validation.validateLeapSecond(month: 12, day: 31) // December 31
    ///
    /// // Invalid leap second date
    /// try RFC_3339.Validation.validateLeapSecond(month: 1, day: 1)   // throws
    /// ```
    public static func validateLeapSecond(month: Int, day: Int) throws {
        let isValidLeapSecondDate = (month == 6 && day == 30) || (month == 12 && day == 31)

        guard isValidLeapSecondDate else {
            throw RFC_3339.Parser.Error.invalidLeapSecond(month: month, day: day)
        }
    }
}
