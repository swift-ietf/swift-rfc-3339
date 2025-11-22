// RFC_3339.swift
// swift-rfc-3339
//
// RFC 3339: Date and Time on the Internet: Timestamps

/// RFC 3339: Date and Time on the Internet
///
/// Authoritative namespace for RFC 3339 date-time format implementations.
///
/// ## Overview
///
/// RFC 3339 defines a profile of ISO 8601 for use in internet protocols.
/// It specifies an unambiguous, sortable, and human-readable date-time format
/// suitable for logging, APIs, and data interchange.
///
/// ## Format Specification
///
/// RFC 3339 timestamps use the extended ISO 8601 format:
/// ```
/// date-time = full-date "T" full-time
/// full-date = date-fullyear "-" date-month "-" date-mday
/// full-time = partial-time time-offset
/// partial-time = time-hour ":" time-minute ":" time-second [time-secfrac]
/// time-offset = "Z" / time-numoffset
/// time-numoffset = ("+" / "-") time-hour ":" time-minute
/// ```
///
/// Examples:
/// ```
/// 1985-04-12T23:20:50.52Z
/// 1996-12-19T16:39:57-08:00
/// 1990-12-31T23:59:60Z          // leap second
/// 1990-12-31T15:59:60-08:00     // leap second with offset
/// 1937-01-01T12:00:27.87+00:20
/// ```
///
/// ## Key Features
///
/// - **Extended format only**: Always includes hyphens in dates, colons in times
/// - **Mandatory fields**: All components must be present (no truncation)
/// - **Explicit timezone**: Either "Z" (UTC) or numeric offset (±HH:MM)
/// - **Fractional seconds**: Optional, arbitrary precision (typically milliseconds to nanoseconds)
/// - **Leap seconds**: Second value 60 allowed on June 30 or December 31
///
/// ## Semantic Distinctions
///
/// RFC 3339 Section 4.3 defines special offset semantics:
/// - `Z` or `+00:00`: UTC time, local offset is zero
/// - `-00:00`: UTC time known, but local offset unknown
///
/// These are semantically different but represent the same instant.
///
/// ## Usage
///
/// ```swift
/// // Parsing
/// let timestamp = "2024-11-22T14:30:00Z"
/// let dateTime = try RFC_3339.Parser.parse(timestamp)
///
/// // Formatting
/// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
/// let formatted = RFC_3339.Formatter.format(time, offset: .utc)
/// // "2024-11-22T14:30:00Z"
///
/// // With offset
/// let offsetTime = RFC_3339.DateTime(time: time, offset: .offset(seconds: -28800))
/// let formatted2 = RFC_3339.Formatter.format(offsetTime)
/// // "2024-11-22T14:30:00-08:00"
/// ```
///
/// ## See Also
///
/// - ``DateTime``
/// - ``Offset``
/// - ``Parser``
/// - ``Formatter``
/// - ``Validation``
public enum RFC_3339 {}
