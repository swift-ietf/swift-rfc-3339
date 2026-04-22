// RFC_3339.swift
// swift-rfc-3339

/// RFC 3339: Date and Time on the Internet: Timestamps
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
/// date-time     = full-date "T" full-time
/// full-date     = date-fullyear "-" date-month "-" date-mday
/// full-time     = partial-time time-offset
/// partial-time  = time-hour ":" time-minute ":" time-second [time-secfrac]
/// time-offset   = "Z" / time-numoffset
/// time-numoffset= ("+" / "-") time-hour ":" time-minute
/// ```
///
/// ## Key Types
///
/// - ``DateTime``: Complete date-time with offset
/// - ``Offset``: UTC offset representation
///
/// ## Example
///
/// ```swift
/// // Parse from string
/// let dt = try RFC_3339.DateTime("2024-11-22T14:30:00Z")
///
/// // Create from components
/// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
/// let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
///
/// // Format to string
/// let formatted = String(dateTime)  // "2024-11-22T14:30:00Z"
/// ```
///
/// ## See Also
///
/// - ``DateTime``
/// - ``Offset``
/// - ``Validation``
/// - [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339)
public enum RFC_3339 {}
