# swift-rfc-3339

Use this package when you read or write Internet timestamps such as `2024-11-22T14:30:00Z`, as found in JSON APIs, logs and feeds. Start from `RFC_3339.DateTime`, which pairs a `Gregorian.DateTime` with an `RFC_3339.Offset`. For week dates, ordinal dates, durations and the other ISO 8601 forms, use swift-iso-8601.

## Laws

- Parsing accepts `t` and `z` in either case. Output always uses `T` and `Z`.
- `+00:00` parses as `RFC_3339.Offset.utc` and prints as `Z`. `-00:00` parses as `RFC_3339.Offset.unknownLocalOffset` and prints as `-00:00` again. The two are not equal, but both have zero `seconds` and `isUTC` is true for both.
- The day is checked against its month and year, so `2024-02-29` is accepted and `2024-02-30` is refused.
- There are no leap seconds. The grammar admits second `60`, but `Gregorian.DateTime` has uniform 86 400-second days, so `1990-12-31T23:59:60Z` is refused with `unsupportedLeapSecond` instead of being read as the next midnight.
- Fractional seconds keep at most nine digits. Further digits are dropped, not rounded.
- Without a precision, the fraction is printed with trailing zeros removed and left out when it is zero. With a precision, it is printed to exactly that many digits, truncated rather than rounded. A precision is clamped to 0 through 9, and 0 prints no fraction.
- Printing always gives text that parses again. A year outside 0000 to 9999 is clamped into that range, and an offset beyond 23:59 either way is clamped to `+23:59` or `-23:59`.
- `RFC_3339.Offset.init(seconds:)` turns zero into `RFC_3339.Offset.utc` and refuses anything beyond 23:59 either way.
- `RFC_3339.DateTime` encodes as its RFC 3339 string, and decoding parses the string the same way the initializer does.
