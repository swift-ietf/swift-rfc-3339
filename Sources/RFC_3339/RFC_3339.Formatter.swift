// RFC_3339.Formatter.swift
// swift-rfc-3339
//
// RFC 3339 Section 5.6: Internet Date/Time Format - Formatting

extension RFC_3339 {
    /// RFC 3339 timestamp formatter
    ///
    /// Formats ``DateTime`` values into RFC 3339 compliant strings.
    ///
    /// ## Format
    ///
    /// Outputs extended ISO 8601 format with all separators:
    /// ```
    /// YYYY-MM-DDTHH:MM:SS[.fraction]±HH:MM
    /// ```
    ///
    /// ## Examples
    ///
    /// ```swift
    /// let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
    ///
    /// // UTC
    /// RFC_3339.Formatter.format(time, offset: .utc)
    /// // "2024-11-22T14:30:00Z"
    ///
    /// // With offset
    /// RFC_3339.Formatter.format(time, offset: .offset(seconds: -28800))
    /// // "2024-11-22T14:30:00-08:00"
    ///
    /// // With millisecond precision
    /// RFC_3339.Formatter.format(time, offset: .utc, precision: 3)
    /// // "2024-11-22T14:30:00.000Z"
    ///
    /// // Unknown local offset
    /// RFC_3339.Formatter.format(time, offset: .unknownLocalOffset)
    /// // "2024-11-22T14:30:00-00:00"
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``DateTime``
    /// - ``Parser``
    public enum Formatter {}
}

// MARK: - Format DateTime

extension RFC_3339.Formatter {
    /// Format a DateTime to RFC 3339 string
    ///
    /// - Parameters:
    ///   - dateTime: The date-time to format
    ///   - precision: Optional fractional seconds precision (0-9 digits). If nil, includes all non-zero sub-second components.
    /// - Returns: RFC 3339 formatted string
    public static func format(_ dateTime: RFC_3339.DateTime, precision: Int? = nil) -> String {
        format(dateTime.time, offset: dateTime.offset, precision: precision)
    }
}

// MARK: - Format Time with Offset

extension RFC_3339.Formatter {
    /// Format a Time with specified offset to RFC 3339 string
    ///
    /// - Parameters:
    ///   - time: The time to format
    ///   - offset: UTC offset
    ///   - precision: Optional fractional seconds precision (0-9 digits). If nil, includes all non-zero sub-second components.
    /// - Returns: RFC 3339 formatted string
    public static func format(
        _ time: Time,
        offset: RFC_3339.Offset,
        precision: Int? = nil
    ) -> String {
        var result = ""
        result.reserveCapacity(35)  // Typical length with nanoseconds

        // full-date: YYYY-MM-DD
        appendYear(&result, time.year.value)
        result.append("-")
        appendTwoDigits(&result, time.month.rawValue)
        result.append("-")
        appendTwoDigits(&result, time.day.rawValue)

        // 'T' separator
        result.append("T")

        // partial-time: HH:MM:SS
        appendTwoDigits(&result, time.hour.value)
        result.append(":")
        appendTwoDigits(&result, time.minute.value)
        result.append(":")
        appendTwoDigits(&result, time.second.value)

        // time-secfrac (optional)
        if let precision = precision {
            appendFraction(&result, time: time, precision: precision)
        } else {
            appendFractionIfNonZero(&result, time: time)
        }

        // time-offset
        appendOffset(&result, offset: offset)

        return result
    }
}

// MARK: - Component Formatting

extension RFC_3339.Formatter {
    /// Append 4-digit year
    private static func appendYear(_ result: inout String, _ year: Int) {
        let absYear = abs(year)
        if year < 0 {
            result.append("-")
        }
        if absYear < 10 {
            result.append("000")
        } else if absYear < 100 {
            result.append("00")
        } else if absYear < 1000 {
            result.append("0")
        }
        result.append(String(absYear))
    }

    /// Append 2-digit number with leading zero if needed
    private static func appendTwoDigits(_ result: inout String, _ value: Int) {
        if value < 10 {
            result.append("0")
        }
        result.append(String(value))
    }

    /// Append fractional seconds with specified precision
    private static func appendFraction(_ result: inout String, time: Time, precision: Int) {
        guard precision > 0 && precision <= 9 else { return }

        result.append(".")

        let totalNanos = time.totalNanoseconds
        // Calculate divisor: 10^(9 - precision)
        var divisor = 1
        for _ in 0..<(9 - precision) {
            divisor *= 10
        }
        let truncated = totalNanos / divisor

        var fractionString = String(truncated)
        // Pad with leading zeros to reach requested precision
        while fractionString.count < precision {
            fractionString = "0" + fractionString
        }

        result.append(fractionString)
    }

    /// Append fractional seconds only if non-zero
    private static func appendFractionIfNonZero(_ result: inout String, time: Time) {
        let totalNanos = time.totalNanoseconds
        guard totalNanos > 0 else { return }

        result.append(".")

        // Format with full precision, then trim trailing zeros
        var fractionString = String(totalNanos)

        // Pad to 9 digits
        while fractionString.count < 9 {
            fractionString = "0" + fractionString
        }

        // Remove trailing zeros
        while fractionString.last == "0" {
            fractionString.removeLast()
        }

        result.append(fractionString)
    }

    /// Append timezone offset
    private static func appendOffset(_ result: inout String, offset: RFC_3339.Offset) {
        switch offset {
        case .utc:
            result.append("Z")

        case .unknownLocalOffset:
            result.append("-00:00")

        case .offset(let seconds):
            let sign = seconds >= 0 ? "+" : "-"
            let absSeconds = abs(seconds)
            let hours = absSeconds / 3600
            let minutes = (absSeconds % 3600) / 60

            result.append(sign)
            appendTwoDigits(&result, hours)
            result.append(":")
            appendTwoDigits(&result, minutes)
        }
    }
}
