import Testing

@testable import RFC_3339

extension RFC_3339.DateTime.Test {
    @Suite
    struct `Parser UTC` {
        @Test
        func `Parse simple UTC timestamp`() throws {
            let input = "2024-11-22T14:30:00Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 2024)
            #expect(dt.time.month == 11)
            #expect(dt.time.day == 22)
            #expect(dt.time.hour.value == 14)
            #expect(dt.time.minute.value == 30)
            #expect(dt.time.second.value == 0)
            #expect(dt.offset == .utc)
        }

        @Test
        func `Parse lowercase 'z' offset`() throws {
            let input = "2024-11-22T14:30:00z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 2024)
            #expect(dt.offset == .utc)
        }

        @Test
        func `Parse +00:00 as UTC`() throws {
            let input = "2024-11-22T14:30:00+00:00"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.offset == .utc)
            #expect(dt.offset.seconds == 0)
        }

        @Test
        func `Z and +00:00 are semantically identical`() throws {
            let withZ = try RFC_3339.DateTime("2024-11-22T14:30:00Z")
            let withPlus = try RFC_3339.DateTime("2024-11-22T14:30:00+00:00")

            #expect(withZ.offset == withPlus.offset)
            #expect(withZ.offset == .utc)
            #expect(withPlus.offset == .utc)
        }
    }

    @Suite
    struct `Parser Numeric Offset` {
        @Test
        func `Parse timestamp with positive offset`() throws {
            let input = "2024-11-22T14:30:00+05:30"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 2024)
            #expect(dt.offset == .offset(seconds: 19800))
        }

        @Test
        func `Parse timestamp with negative offset`() throws {
            let input = "2024-11-22T14:30:00-08:00"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 2024)
            #expect(dt.offset == .offset(seconds: -28800))
        }

        @Test
        func `Parse unknown local offset`() throws {
            let input = "2024-11-22T14:30:00-00:00"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.offset == .unknownLocalOffset)
        }
    }

    @Suite
    struct `Parser Fractional Seconds` {
        @Test
        func `Parse timestamp with fractional seconds`() throws {
            let input = "1985-04-12T23:20:50.52Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 1985)
            #expect(dt.time.millisecond.value == 520)
            #expect(dt.offset == .utc)
        }

        @Test
        func `Parse various fractional second precisions`() throws {
            let inputs = [
                ("2024-01-01T00:00:00.1Z", 100),
                ("2024-01-01T00:00:00.12Z", 120),
                ("2024-01-01T00:00:00.123Z", 123),
                ("2024-01-01T00:00:00.1234Z", 123),
                ("2024-01-01T00:00:00.123456789Z", 123),
            ]

            for (input, expectedMillis) in inputs {
                let dt = try RFC_3339.DateTime(input)
                #expect(dt.time.millisecond.value == expectedMillis)
            }
        }
    }

    @Suite
    struct `Parser Leap Second` {
        @Test
        func `Parse leap second`() throws {
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
    }

    @Suite
    struct `Parser Case Insensitivity` {
        @Test
        func `Parse lowercase 't' separator`() throws {
            let input = "2024-11-22t14:30:00Z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 2024)
            #expect(dt.time.hour.value == 14)
            #expect(dt.offset == .utc)
        }

        @Test
        func `Parse lowercase 't' and 'z'`() throws {
            let input = "2024-11-22t14:30:00z"
            let dt = try RFC_3339.DateTime(input)

            #expect(dt.time.year == 2024)
            #expect(dt.offset == .utc)
        }
    }

    @Suite
    struct `Parser String Protocol` {
        @Test
        func `Parse substring`() throws {
            let full = "timestamp: 2024-11-22T14:30:00Z end"
            let substring = full.dropFirst(11).dropLast(4)

            let dt = try RFC_3339.DateTime(String(substring))

            #expect(dt.time.year == 2024)
            #expect(dt.time.month == 11)
            #expect(dt.time.day == 22)
            #expect(dt.offset == .utc)
        }
    }
}
