// OffsetSerializationEquivalenceTests.swift
// swift-rfc-3339
//
// [FAM-012] composite re-cut guard. The Offset `ASCII.Serializable` verb
// (numeric formatting re-expressed directly over the `ASCII.Code` substrate)
// MUST emit byte-identical output to the `Binary.Serializable` witness
// (`serializeBytes`). The package's existing output assertions exercise the
// offset only through the DateTime byte path, not the new ASCII verb — this
// asserts the refactor invariant directly (ASCII output == Binary output) for
// the non-trivial numeric/sign/zero-pad paths, so no expected string is
// hand-derived.

import RFC_3339
import Testing

@Suite("RFC_3339.Offset - Serialization Equivalence")
struct OffsetSerializationEquivalenceTests {

    @Test(arguments: [
        RFC_3339.Offset.utc,  // "Z"
        RFC_3339.Offset.unknownLocalOffset,  // "-00:00"
        RFC_3339.Offset.offset(seconds: 19800),  // "+05:30"
        RFC_3339.Offset.offset(seconds: -28800),  // "-08:00"
        RFC_3339.Offset.offset(seconds: 3600),  // "+01:00" (single-digit-hour zero-pad)
    ])
    func `ASCII verb output equals Binary witness output`(offset: RFC_3339.Offset) {
        // ASCII.Serializable verb output, projected to bytes.
        let viaASCII: [Byte] = offset.serialized

        // Binary.Serializable witness output.
        var viaBinary: [Byte] = []
        RFC_3339.Offset.serialize(offset, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
