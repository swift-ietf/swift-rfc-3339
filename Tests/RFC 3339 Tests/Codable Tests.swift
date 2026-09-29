import Foundation
import Testing

@testable import RFC_3339

extension RFC_3339.DateTime.Test {
    @Suite
    struct `JSON Coding` {
        @Test
        func `UTC date-time round-trips through JSON as its RFC 3339 string`() throws {
            let time = try Gregorian.DateTime(year: 2024, month: 11, day: 22, hour: 14, minute: 30, second: 0)
            let dateTime = RFC_3339.DateTime(time: time, offset: .utc)

            let data = try JSONEncoder().encode(dateTime)
            #expect(String(decoding: data, as: UTF8.self) == "\"2024-11-22T14:30:00Z\"")

            let decoded = try JSONDecoder().decode(RFC_3339.DateTime.self, from: data)
            #expect(decoded == dateTime)
        }

        @Test
        func `Offset date-time round-trips through JSON as its RFC 3339 string`() throws {
            let time = try Gregorian.DateTime(
                year: 2024,
                month: 11,
                day: 22,
                hour: 14,
                minute: 30,
                second: 0,
                millisecond: 123
            )
            let dateTime = RFC_3339.DateTime(time: time, offset: try RFC_3339.Offset(seconds: 19800))

            let data = try JSONEncoder().encode(dateTime)
            #expect(String(decoding: data, as: UTF8.self) == "\"2024-11-22T14:30:00.123+05:30\"")

            let decoded = try JSONDecoder().decode(RFC_3339.DateTime.self, from: data)
            #expect(decoded == dateTime)
        }
    }
}
