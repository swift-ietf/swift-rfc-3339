import Testing

@testable import RFC_3339

extension RFC_3339.DateTime.Test {
    @Suite
    struct `Leap Second Offset` {
        @Test
        func `RFC 5,8 example west-offset leap second parses`() throws {

            let dt = try RFC_3339.DateTime("1990-12-31T15:59:60-08:00")
            #expect(dt.time.second.value == 60)
            #expect(dt.offset.seconds == -8 * 3600)
        }

        @Test
        func `East-offset leap second on local January 1 parses`() throws {

            let dt = try RFC_3339.DateTime("1991-01-01T00:59:60+01:00")
            #expect(dt.time.second.value == 60)
            #expect(dt.time.month == 1)
            #expect(dt.time.day == 1)
        }

        @Test
        func `East-offset leap second on local July 1 parses`() throws {

            let dt = try RFC_3339.DateTime("2015-07-01T08:59:60+09:00")
            #expect(dt.time.second.value == 60)
        }

        @Test
        func `Leap second at wrong UTC time of day is rejected`() throws {

            #expect(throws: RFC_3339.DateTime.Error.self) {
                _ = try RFC_3339.DateTime("1990-12-31T12:00:60Z")
            }
        }

        @Test
        func `Local December 31 leap second at wrong UTC instant is rejected`() throws {

            #expect(throws: RFC_3339.DateTime.Error.self) {
                _ = try RFC_3339.DateTime("1990-12-31T23:59:60+09:00")
            }
        }

        @Test
        func `UTC leap second on December 31 still parses`() throws {
            let dt = try RFC_3339.DateTime("1990-12-31T23:59:60Z")
            #expect(dt.time.second.value == 60)
        }
    }
}
