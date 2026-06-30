// DateTimeSerializationEquivalenceTests.swift
// swift-rfc-3339
//
// [FAM-012] composite re-cut guard. The DateTime `ASCII.Serializable` verb
// (numeric date/time formatting re-expressed directly over the `ASCII.Code`
// substrate, composing the re-cut `Offset` ASCII verb) MUST emit byte-identical
// output to the `Binary.Serializable` witness (`serializeBytes`). The package's
// existing formatter assertions exercise exact strings; this asserts the refactor
// invariant directly (ASCII output == Binary output) for the non-trivial
// numeric/zero-pad/fraction-trim paths, so no expected string is hand-derived.

import RFC_3339
import Testing

@Suite("RFC_3339.DateTime - Serialization Equivalence")
struct DateTimeSerializationEquivalenceTests {

    @Test
    func `ASCII verb output equals Binary witness output`() throws {
        // A non-zero fractional second forces the fraction-trim branch and a
        // non-UTC numeric offset forces the sign/zero-pad branch of the re-cut
        // Offset verb — the paths transcribed into the ASCII verb.
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
            offset: .offset(seconds: 19800)  // +05:30
        )

        // ASCII.Serializable verb output, projected to bytes.
        let viaASCII: [Byte] = dateTime.serialized

        // Binary.Serializable witness output.
        var viaBinary: [Byte] = []
        RFC_3339.DateTime.serialize(dateTime, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }

    @Test
    func `ASCII verb output equals Binary witness output with explicit precision`() throws {
        // Explicit precision forces the fixed-precision fraction branch; a
        // negative offset forces the hyphen-sign branch.
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
            offset: .offset(seconds: -28800),  // -08:00
            precision: 6
        )

        let viaASCII: [Byte] = dateTime.serialized

        var viaBinary: [Byte] = []
        RFC_3339.DateTime.serialize(dateTime, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
