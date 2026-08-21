import Binary_Serializable_Primitives
import Testing

@testable import RFC_3339

extension RFC_3339.Offset.Test {
    @Suite
    struct `Serialization Totality` {
        @Test
        func `Out-of-range positive raw payload serializes to valid offset`() throws {

            let offset = RFC_3339.Offset.offset(seconds: 100_000)
            let wire = String(decoding: offset.serialized, as: UTF8.self)
            let reparsed = try RFC_3339.Offset(wire)
            #expect(wire == "+23:59")
            #expect(reparsed.seconds == 23 * 3600 + 59 * 60)
        }

        @Test
        func `Out-of-range negative raw payload serializes to valid offset`() throws {
            let offset = RFC_3339.Offset.offset(seconds: -100_000)
            let wire = String(decoding: offset.serialized, as: UTF8.self)
            let reparsed = try RFC_3339.Offset(wire)
            #expect(wire == "-23:59")
            #expect(reparsed.seconds == -(23 * 3600 + 59 * 60))
        }
    }
}

extension RFC_3339.DateTime.Test {
    @Suite
    struct `Serialization Totality` {
        @Test
        func `Year above 9999 serializes to parseable output`() throws {
            let time = try Time(year: 12345, month: 1, day: 2, hour: 3, minute: 4, second: 5)
            let dt = RFC_3339.DateTime(time: time, offset: .utc)
            let wire = String(dt)
            let reparsed = try RFC_3339.DateTime(wire)
            #expect(wire == "9999-01-02T03:04:05Z")
            #expect(reparsed.time.year == 9999)
        }

        @Test
        func `Negative year serializes to parseable output`() throws {
            let time = try Time(year: -1, month: 1, day: 2, hour: 3, minute: 4, second: 5)
            let dt = RFC_3339.DateTime(time: time, offset: .utc)
            let wire = String(dt)
            let reparsed = try RFC_3339.DateTime(wire)
            #expect(wire == "0000-01-02T03:04:05Z")
            #expect(reparsed.time.year == 0)
        }

        @Test
        func `Precision above 9 clamps to nanosecond precision`() throws {
            let time = try Time(
                year: 2024,
                month: 11,
                day: 22,
                hour: 14,
                minute: 30,
                second: 0,
                millisecond: 123,
                microsecond: 456,
                nanosecond: 789
            )
            let dt = RFC_3339.DateTime(time: time, offset: .utc, precision: 15)
            let wire = String(dt)
            #expect(wire == "2024-11-22T14:30:00.123456789Z")
            _ = try RFC_3339.DateTime(wire)
        }

        @Test
        func `Negative precision clamps to zero fractional digits`() throws {
            let time = try Time(
                year: 2024,
                month: 11,
                day: 22,
                hour: 14,
                minute: 30,
                second: 0,
                millisecond: 123
            )
            let dt = RFC_3339.DateTime(time: time, offset: .utc, precision: -3)
            let wire = String(dt)
            #expect(wire == "2024-11-22T14:30:00Z")
            _ = try RFC_3339.DateTime(wire)
        }

        @Test
        func `Raw offset payload round-trips through parse`() throws {
            let time = try Time(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dt = RFC_3339.DateTime(time: time, offset: .offset(seconds: 99_999))
            let wire = String(dt)
            _ = try RFC_3339.DateTime(wire)
        }
    }
}
