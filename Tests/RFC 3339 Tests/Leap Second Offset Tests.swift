import Testing

@testable import RFC_3339

extension `RFC_3339.DateTime Tests`.Test {
    @Suite
    struct `Leap Second Offset` {
        @Test
        func `Leap seconds are refused at every offset`() {
            for input in [
                "1990-12-31T15:59:60-08:00",
                "1991-01-01T00:59:60+01:00",
                "2015-07-01T08:59:60+09:00",
                "1990-12-31T23:59:60Z",
                "1990-12-31T12:00:60Z",
            ] {
                #expect(throws: RFC_3339.DateTime.Error.unsupportedLeapSecond(input)) {
                    _ = try RFC_3339.DateTime(input)
                }
            }
        }

        @Test
        func `Second 61 is an invalid second`() {
            #expect(throws: RFC_3339.DateTime.Error.invalidSecond("61")) {
                _ = try RFC_3339.DateTime("1990-12-31T23:59:61Z")
            }
        }
    }
}
