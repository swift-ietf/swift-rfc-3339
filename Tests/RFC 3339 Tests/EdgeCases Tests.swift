import Binary_Serializable_Primitives
import Testing

@testable import RFC_3339

extension RFC_3339.DateTime.Test {
    @Suite
    struct `Year Boundary` {
        @Test
        func `Parse year 0000 (minimum allowed)`() throws {
            let input = "0000-01-01T00:00:00Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 0)
            #expect(dt.time.month == 1)
            #expect(dt.time.day == 1)
        }

        @Test
        func `Parse year 9999 (maximum allowed)`() throws {
            let input = "9999-12-31T23:59:59Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 9999)
            #expect(dt.time.month == 12)
            #expect(dt.time.day == 31)
        }

        @Test
        func `Format year 0000`() throws {
            let time = try Time(year: 0, month: 1, day: 1, hour: 0, minute: 0, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted == "0000-01-01T00:00:00Z")
        }

        @Test
        func `Format year 9999`() throws {
            let time = try Time(year: 9999, month: 12, day: 31, hour: 23, minute: 59, second: 59)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted == "9999-12-31T23:59:59Z")
        }
    }

    @Suite
    struct `Leap Second` {
        @Test
        func `Leap second on December 31`() throws {
            let input = "1990-12-31T23:59:60Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.second.value == 60)
            #expect(dt.time.month == 12)
            #expect(dt.time.day == 31)
        }

        @Test
        func `Leap second on June 30`() throws {
            let input = "2015-06-30T23:59:60Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.second.value == 60)
            #expect(dt.time.month == 6)
            #expect(dt.time.day == 30)
        }

        @Test
        func `Negative leap second (second=58)`() throws {

            let input = "2024-06-30T23:59:58Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.second.value == 58)

        }

        @Test
        func `Format leap second`() throws {
            let time = try Time(year: 2015, month: 6, day: 30, hour: 23, minute: 59, second: 60)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)
            let formatted = String(dateTime)

            #expect(formatted == "2015-06-30T23:59:60Z")
        }
    }

    @Suite
    struct `Offset Boundary` {
        @Test
        func `Maximum positive offset (+23:59)`() throws {
            let input = "2024-01-01T00:00:00+23:59"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.offset == .offset(seconds: 86340))
        }

        @Test
        func `Maximum negative offset (-23:59)`() throws {
            let input = "2024-01-01T00:00:00-23:59"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.offset == .offset(seconds: -86340))
        }

        @Test
        func `Format maximum positive offset`() throws {
            let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .offset(seconds: 86340))
            let formatted = String(dateTime)

            #expect(formatted == "2024-01-01T00:00:00+23:59")
        }

        @Test
        func `Format maximum negative offset`() throws {
            let time = try Time(year: 2024, month: 1, day: 1, hour: 0, minute: 0, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .offset(seconds: -86340))
            let formatted = String(dateTime)

            #expect(formatted == "2024-01-01T00:00:00-23:59")
        }

        @Test
        func `Zero offset edge cases`() throws {

            let z = try RFC_3339.DateTime("2024-01-01T00:00:00Z")
            let plus = try RFC_3339.DateTime("2024-01-01T00:00:00+00:00")
            let minus = try RFC_3339.DateTime("2024-01-01T00:00:00-00:00")

            #expect(z.offset == .utc)
            #expect(plus.offset == .utc)
            #expect(minus.offset == .unknownLocalOffset)

            #expect(z.offset.seconds == 0)
            #expect(plus.offset.seconds == 0)
            #expect(minus.offset.seconds == 0)

            #expect(z.offset.isUTC)
            #expect(plus.offset.isUTC)
            #expect(minus.offset.isUTC)
        }
    }

    @Suite
    struct `Fractional Second Edge Case` {
        @Test
        func `Single digit fractional second`() throws {
            let input = "2024-01-01T00:00:00.1Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.millisecond.value == 100)
        }

        @Test
        func `Maximum precision (9 digits)`() throws {
            let input = "2024-01-01T00:00:00.123456789Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.millisecond.value == 123)
            #expect(dt.time.microsecond.value == 456)
            #expect(dt.time.nanosecond.value == 789)
        }

        @Test
        func `More than 9 digits truncates`() throws {
            let input = "2024-01-01T00:00:00.1234567890123Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.millisecond.value == 123)
            #expect(dt.time.microsecond.value == 456)
            #expect(dt.time.nanosecond.value == 789)
        }

        @Test
        func `Format precision 0 omits decimal point`() throws {
            let time = try Time(
                year: 2024,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 123
            )
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc, precision: 0)
            let formatted = String(dateTime)

            #expect(formatted == "2024-01-01T00:00:00Z")
            #expect(!formatted.contains("."))
        }

        @Test
        func `Format precision 9 (nanoseconds)`() throws {
            let time = try Time(
                year: 2024,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 1,
                microsecond: 2,
                nanosecond: 3
            )
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc, precision: 9)
            let formatted = String(dateTime)

            #expect(formatted == "2024-01-01T00:00:00.001002003Z")
        }
    }

    @Suite
    struct `Component Boundary` {
        @Test
        func `Midnight (start of day)`() throws {
            let input = "2024-01-01T00:00:00Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.hour.value == 0)
            #expect(dt.time.minute.value == 0)
            #expect(dt.time.second.value == 0)
        }

        @Test
        func `End of day (just before midnight)`() throws {
            let input = "2024-01-01T23:59:59Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.hour.value == 23)
            #expect(dt.time.minute.value == 59)
            #expect(dt.time.second.value == 59)
        }

        @Test
        func `First day of year`() throws {
            let input = "2024-01-01T00:00:00Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.month == 1)
            #expect(dt.time.day == 1)
        }

        @Test
        func `Last day of year`() throws {
            let input = "2024-12-31T23:59:59Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.month == 12)
            #expect(dt.time.day == 31)
        }

        @Test
        func `Leap year February 29`() throws {
            let input = "2024-02-29T12:00:00Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 2024)
            #expect(dt.time.month == 2)
            #expect(dt.time.day == 29)
        }
    }
}
