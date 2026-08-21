import RFC_3339
import Testing

extension RFC_3339.DateTime {
    @Suite("RFC_3339.DateTime - Serialization Equivalence")
    struct Test {

        @Test
        func `ASCII verb output equals Binary witness output`() throws {

            let time = try Time(
                year: 2024,
                month: 11,
                day: 22,
                hour: 14,
                minute: 30,
                second: 5,
                millisecond: 123,
                microsecond: 0,
                nanosecond: 0
            )
            let dateTime = RFC_3339.DateTime(
                time: time,
                offset: .offset(seconds: 19800)
            )

            let viaASCII: [Byte] = dateTime.serialized

            var viaBinary: [Byte] = []
            RFC_3339.DateTime.serialize(dateTime, into: &viaBinary)

            #expect(viaASCII == viaBinary)
        }

        @Test
        func `ASCII verb output equals Binary witness output with explicit precision`() throws {

            let time = try Time(
                year: 2024,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 123,
                microsecond: 456,
                nanosecond: 0
            )
            let dateTime = RFC_3339.DateTime(
                time: time,
                offset: .offset(seconds: -28800),
                precision: 6
            )

            let viaASCII: [Byte] = dateTime.serialized

            var viaBinary: [Byte] = []
            RFC_3339.DateTime.serialize(dateTime, into: &viaBinary)

            #expect(viaASCII == viaBinary)
        }
    }
}
