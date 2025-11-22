// String+RFC_3339.swift
// swift-rfc-3339
//
// RFC 3339 extensions for String

extension RFC_3339 {
    /// RFC 3339 wrapper for String
    ///
    /// Provides RFC 3339 parsing operations on String values.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let timestamp = "2024-11-22T14:30:00Z"
    ///
    /// // Parse
    /// let dateTime = try timestamp.rfc3339.parse()
    /// print(dateTime.time.year)  // 2024
    /// print(dateTime.offset)     // .utc
    ///
    /// // Validate
    /// if timestamp.rfc3339.isValid {
    ///     print("Valid RFC 3339 timestamp")
    /// }
    /// ```
    public struct StringWrapper {
        public let value: String

        internal init(_ value: String) {
            self.value = value
        }
    }
}

// MARK: - String Extension

extension String {
    /// Access RFC 3339 operations for this string
    ///
    /// Provides a namespace for RFC 3339 parsing and validation.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let timestamp = "2024-11-22T14:30:00Z"
    /// let dateTime = try timestamp.rfc3339.parse()
    /// ```
    public var rfc3339: RFC_3339.StringWrapper {
        RFC_3339.StringWrapper(self)
    }
}

// MARK: - Parsing

extension RFC_3339.StringWrapper {
    /// Parse string as RFC 3339 timestamp
    ///
    /// - Returns: Parsed date-time
    /// - Throws: ``RFC_3339.Parser.Error`` if format is invalid
    ///
    /// ## Examples
    ///
    /// ```swift
    /// let dt1 = try "1985-04-12T23:20:50.52Z".rfc3339.parse()
    ///
    /// let dt2 = try "1996-12-19T16:39:57-08:00".rfc3339.parse()
    ///
    /// let dt3 = try "1990-12-31T23:59:60Z".rfc3339.parse()  // leap second
    /// ```
    public func parse() throws -> RFC_3339.DateTime {
        try RFC_3339.Parser.parse(value)
    }

    /// Check if string is a valid RFC 3339 timestamp
    ///
    /// - Returns: true if the string can be parsed as RFC 3339
    ///
    /// ## Example
    ///
    /// ```swift
    /// "2024-11-22T14:30:00Z".rfc3339.isValid  // true
    /// "2024-11-22 14:30:00".rfc3339.isValid   // false (missing 'T')
    /// "invalid".rfc3339.isValid               // false
    /// ```
    public var isValid: Bool {
        (try? parse()) != nil
    }
}
