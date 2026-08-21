import Binary_Serializable_Primitives
import Testing

@testable import RFC_3339

extension RFC_3339.DateTime.Test {
    @Suite
    struct `Formatter UTC` {
        @Test
        func `Format simple UTC timestamp`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted == "2024-11-22T14:30:00Z")
        }

        @Test
        func `Format UTC uses 'Z' not '+00:00'`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted.hasSuffix("Z"))
            #expect(!formatted.contains("+00:00"))
        }
    }

    @Suite
    struct `Formatter Numeric Offset` {
        @Test
        func `Format with positive offset`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .offset(seconds: 19800))
            let formatted = String(dateTime)

            #expect(formatted == "2024-11-22T14:30:00+05:30")
        }

        @Test
        func `Format with negative offset`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .offset(seconds: -28800))
            let formatted = String(dateTime)

            #expect(formatted == "2024-11-22T14:30:00-08:00")
        }

        @Test
        func `Format unknown local offset`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .unknownLocalOffset)
            let formatted = String(dateTime)

            #expect(formatted == "2024-11-22T14:30:00-00:00")
        }

        @Test
        func `Format various timezone offsets`() throws {
            let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)

            let testCases: [(seconds: Int, expected: String)] = [
                (-43200, "2024-01-01T00:00:00-12:00"),
                (-28800, "2024-01-01T00:00:00-08:00"),
                (-18000, "2024-01-01T00:00:00-05:00"),
                (3600, "2024-01-01T00:00:00+01:00"),
                (19800, "2024-01-01T00:00:00+05:30"),
                (32400, "2024-01-01T00:00:00+09:00"),
                (43200, "2024-01-01T00:00:00+12:00"),
            ]

            for (seconds, expected) in testCases {
                let dateTime = RFC_3339.DateTime(time: time, offset: .offset(seconds: seconds))
                let formatted = String(dateTime)
                #expect(formatted == expected)
            }
        }
    }

    @Suite
    struct `Formatter Fractional Seconds` {
        @Test
        func `Format with millisecond precision`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc, precision: 3)
            let formatted = String(dateTime)

            #expect(formatted == "2024-11-22T14:30:00.000Z")
        }

        @Test
        func `Format with various precisions`() throws {
            let time = try Time(
                year: 2024,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 123,
                microsecond: 456,
                nanosecond: 789
            )

            let testCases: [(precision: Int, expected: String)] = [
                (0, "2024-01-01T00:00:00Z"),
                (1, "2024-01-01T00:00:00.1Z"),
                (2, "2024-01-01T00:00:00.12Z"),
                (3, "2024-01-01T00:00:00.123Z"),
                (6, "2024-01-01T00:00:00.123456Z"),
                (9, "2024-01-01T00:00:00.123456789Z"),
            ]

            for (precision, expected) in testCases {
                let dateTime = RFC_3339.DateTime(time: time, offset: .utc, precision: precision)
                let formatted = String(dateTime)
                #expect(formatted == expected)
            }
        }

        @Test
        func `Format without precision omits zero fractional seconds`() throws {
            let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted == "2024-01-01T00:00:00Z")
            #expect(!formatted.contains("."))
        }

        @Test
        func `Format without precision includes non-zero fractional seconds`() throws {
            let time = try Time(
                year: 2024,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 123
            )
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted == "2024-01-01T00:00:00.123Z")
        }
    }

    @Suite
    struct `Formatter DateTime` {
        @Test
        func `Format DateTime directly`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted == "2024-11-22T14:30:00Z")
        }

        @Test
        func `Format DateTime with precision`() throws {
            let time = try Time(
                year: 2024,
                month: 11,
                day: 22,
                hour: 14,
                minute: 30,
                second: 0,
                millisecond: 123
            )
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc, precision: 3)
            let formatted = String(dateTime)

            #expect(formatted == "2024-11-22T14:30:00.123Z")
        }
    }
}
