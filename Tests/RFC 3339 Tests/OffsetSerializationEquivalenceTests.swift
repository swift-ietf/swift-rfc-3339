import RFC_3339
import Testing

extension RFC_3339.Offset.Test {
    @Suite
    struct `Serialization Equivalence` {

        @Test(arguments: [
            RFC_3339.Offset.utc,
            RFC_3339.Offset.unknownLocalOffset,
            RFC_3339.Offset.offset(seconds: 19800),
            RFC_3339.Offset.offset(seconds: -28800),
            RFC_3339.Offset.offset(seconds: 3600),
        ])
        func `ASCII verb output equals Binary witness output`(offset: RFC_3339.Offset) {

            let viaASCII: [Byte] = offset.serialized

            var viaBinary: [Byte] = []
            RFC_3339.Offset.serialize(offset, into: &viaBinary)

            #expect(viaASCII == viaBinary)
        }
    }
}
