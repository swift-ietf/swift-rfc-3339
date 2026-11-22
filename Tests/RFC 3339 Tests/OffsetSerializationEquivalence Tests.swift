import RFC_3339
import Testing

extension `IETF.RFC.3339.Offset Tests`.Test {
    @Suite
    struct `Serialization Equivalence` {

        @Test(arguments: [
            IETF.RFC.`3339`.Offset.utc,
            IETF.RFC.`3339`.Offset.unknownLocalOffset,
            IETF.RFC.`3339`.Offset.offset(seconds: 19800),
            IETF.RFC.`3339`.Offset.offset(seconds: -28800),
            IETF.RFC.`3339`.Offset.offset(seconds: 3600),
        ])
        func `ASCII verb output equals Binary witness output`(offset: IETF.RFC.`3339`.Offset) {

            let viaASCII: [Byte] = offset.serialized

            var viaBinary: [Byte] = []
            IETF.RFC.`3339`.Offset.serialize(offset, into: &viaBinary)

            #expect(viaASCII == viaBinary)
        }
    }
}
