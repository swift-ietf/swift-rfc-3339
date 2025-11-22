// RFC_3339.Offset.swift
// swift-rfc-3339
//
// RFC 3339 Section 4.3: Internet Date/Time Format - Offset specification

extension RFC_3339 {
    /// UTC offset for RFC 3339 timestamps
    ///
    /// Represents the timezone offset component of an RFC 3339 date-time.
    ///
    /// ## Semantic Distinctions
    ///
    /// RFC 3339 Section 4.3 defines important semantic differences:
    ///
    /// - **UTC (Z or +00:00)**: The time is in UTC and the local offset is zero
    /// - **Unknown local offset (-00:00)**: The time is in UTC but the local offset is unknown
    /// - **Numeric offset**: The time is in a specific timezone
    ///
    /// The distinction between `.utc` and `.unknownLocalOffset` is semantic only;
    /// both represent the same instant in time but convey different information about
    /// the generating system's timezone knowledge.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // UTC time
    /// let utc = RFC_3339.Offset.utc
    /// // Formats as "Z" or "+00:00"
    ///
    /// // Unknown local offset
    /// let unknown = RFC_3339.Offset.unknownLocalOffset
    /// // Formats as "-00:00"
    ///
    /// // Pacific Standard Time (UTC-8)
    /// let pst = RFC_3339.Offset.offset(seconds: -28800)
    /// // Formats as "-08:00"
    ///
    /// // India Standard Time (UTC+5:30)
    /// let ist = RFC_3339.Offset.offset(seconds: 19800)
    /// // Formats as "+05:30"
    /// ```
    ///
    /// ## Valid Range
    ///
    /// RFC 3339 allows offsets from -23:59 to +23:59, though IANA timezone database
    /// uses a more restricted range of approximately -12:00 to +14:00.
    ///
    /// ## See Also
    ///
    /// - ``DateTime``
    /// - ``Formatter``
    public enum Offset: Sendable, Equatable, Hashable {
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
        ///
        /// This preserves the semantic information that UTC is known but local
        /// context has been lost (e.g., from timezone-unaware storage).
        case unknownLocalOffset

        /// Numeric timezone offset in seconds
        ///
        /// - Parameter seconds: Offset from UTC in seconds, positive for east, negative for west
        ///
        /// Common offsets:
        /// - Pacific: -28800 (-08:00)
        /// - Mountain: -25200 (-07:00)
        /// - Central: -21600 (-06:00)
        /// - Eastern: -18000 (-05:00)
        /// - UK: 0 (+00:00) - prefer `.utc` instead
        /// - Central European: 3600 (+01:00)
        /// - India: 19800 (+05:30)
        /// - China: 28800 (+08:00)
        /// - Japan: 32400 (+09:00)
        case offset(seconds: Int)
    }
}

// MARK: - Computed Properties

extension RFC_3339.Offset {
    /// Offset in seconds from UTC
    ///
    /// - Returns: Seconds offset (positive for east of UTC, negative for west)
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
        /// Offset seconds out of valid range (-86340 to +86340, i.e., -23:59 to +23:59)
        case offsetOutOfRange(Int)
    }

    /// Create offset from seconds with validation
    ///
    /// Validates that the offset is within RFC 3339 allowed range of ±23:59.
    ///
    /// - Parameter seconds: Offset in seconds from UTC
    /// - Returns: Validated offset
    /// - Throws: ``Error/offsetOutOfRange(_:)`` if seconds is outside valid range
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let offset = try RFC_3339.Offset(seconds: -28800)  // -08:00 PST
    /// let invalid = try RFC_3339.Offset(seconds: 100000) // throws
    /// ```
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
