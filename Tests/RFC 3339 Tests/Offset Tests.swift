// Offset Tests.swift
// swift-rfc-3339
//
// Comprehensive tests for RFC_3339.Offset

import Testing

@testable import RFC_3339

// MARK: - Offset Creation

@Suite("RFC_3339.Offset - Creation and Validation")
struct OffsetCreationTests {
    @Test
    func `Create offset from valid seconds`() throws {
        let offset = try RFC_3339.Offset(seconds: -28800)
        #expect(offset == .offset(seconds: -28800))
        #expect(offset.seconds == -28800)
    }

    @Test
    func `Create offset from zero seconds becomes UTC`() throws {
        let offset = try RFC_3339.Offset(seconds: 0)
        #expect(offset == .utc)
        #expect(offset.seconds == 0)
    }

    @Test
    func `Maximum valid offset`() throws {
        let maxSeconds = 23 * 3600 + 59 * 60  // 23:59
        let offset = try RFC_3339.Offset(seconds: maxSeconds)
        #expect(offset == .offset(seconds: 86340))
    }

    @Test
    func `Minimum valid offset`() throws {
        let minSeconds = -(23 * 3600 + 59 * 60)  // -23:59
        let offset = try RFC_3339.Offset(seconds: minSeconds)
        #expect(offset == .offset(seconds: -86340))
    }

    @Test
    func `Offset beyond maximum throws error`() {
        let tooLarge = 24 * 3600  // 24:00
        #expect(throws: RFC_3339.Offset.Error.self) {
            _ = try RFC_3339.Offset(seconds: tooLarge)
        }
    }

    @Test
    func `Offset beyond minimum throws error`() {
        let tooSmall = -(24 * 3600)  // -24:00
        #expect(throws: RFC_3339.Offset.Error.self) {
            _ = try RFC_3339.Offset(seconds: tooSmall)
        }
    }
}

// MARK: - Offset Semantics

@Suite("RFC_3339.Offset - Semantic Distinctions")
struct OffsetSemanticsTests {
    @Test
    func `UTC has zero seconds`() {
        let offset = RFC_3339.Offset.utc
        #expect(offset.seconds == 0)
        #expect(offset.isUTC)
    }

    @Test
    func `Unknown local offset has zero seconds`() {
        let offset = RFC_3339.Offset.unknownLocalOffset
        #expect(offset.seconds == 0)
        #expect(offset.isUTC)
    }

    @Test
    func `UTC and unknown local offset are different`() {
        let utc = RFC_3339.Offset.utc
        let unknown = RFC_3339.Offset.unknownLocalOffset

        #expect(utc != unknown)
        #expect(utc.seconds == unknown.seconds)  // Same seconds
        #expect(utc.isUTC && unknown.isUTC)  // Both are UTC
    }

    @Test
    func `Numeric offset with zero seconds becomes UTC via init`() throws {
        let offset = try RFC_3339.Offset(seconds: 0)
        #expect(offset == .utc)
        #expect(offset != .unknownLocalOffset)
    }
}

// MARK: - Offset Equality

@Suite("RFC_3339.Offset - Equality")
struct OffsetEqualityTests {
    @Test
    func `UTC equals itself`() {
        #expect(RFC_3339.Offset.utc == .utc)
    }

    @Test
    func `Unknown local offset equals itself`() {
        #expect(RFC_3339.Offset.unknownLocalOffset == .unknownLocalOffset)
    }

    @Test
    func `Same numeric offsets are equal`() {
        let offset1 = RFC_3339.Offset.offset(seconds: -28800)
        let offset2 = RFC_3339.Offset.offset(seconds: -28800)
        #expect(offset1 == offset2)
    }

    @Test
    func `Different numeric offsets are not equal`() {
        let offset1 = RFC_3339.Offset.offset(seconds: -28800)
        let offset2 = RFC_3339.Offset.offset(seconds: 19800)
        #expect(offset1 != offset2)
    }
}

// MARK: - Offset Properties

@Suite("RFC_3339.Offset - Properties")
struct OffsetPropertiesTests {
    @Test
    func `isUTC true for UTC`() {
        #expect(RFC_3339.Offset.utc.isUTC)
    }

    @Test
    func `isUTC true for unknown local offset`() {
        #expect(RFC_3339.Offset.unknownLocalOffset.isUTC)
    }

    @Test
    func `isUTC false for non-zero offsets`() {
        let offset = RFC_3339.Offset.offset(seconds: -28800)
        #expect(!offset.isUTC)
    }

    @Test
    func `Seconds property for various offsets`() {
        #expect(RFC_3339.Offset.utc.seconds == 0)
        #expect(RFC_3339.Offset.unknownLocalOffset.seconds == 0)
        #expect(RFC_3339.Offset.offset(seconds: 3600).seconds == 3600)
        #expect(RFC_3339.Offset.offset(seconds: -28800).seconds == -28800)
    }
}

// MARK: - Common Timezone Offsets

@Suite("RFC_3339.Offset - Common Timezones")
struct CommonTimezoneTests {
    @Test
    func `Common timezone offsets`() throws {
        let timezones: [(name: String, seconds: Int)] = [
            ("UTC-12", -43200),
            ("PST (UTC-8)", -28800),
            ("EST (UTC-5)", -18000),
            ("UTC+0", 0),
            ("CET (UTC+1)", 3600),
            ("IST (UTC+5:30)", 19800),
            ("JST (UTC+9)", 32400),
            ("UTC+12", 43200),
        ]

        for (name, seconds) in timezones {
            if seconds == 0 {
                let offset = try RFC_3339.Offset(seconds: seconds)
                #expect(offset == .utc, "Failed for \(name)")
            } else {
                let offset = try RFC_3339.Offset(seconds: seconds)
                #expect(offset == .offset(seconds: seconds), "Failed for \(name)")
                #expect(offset.seconds == seconds, "Failed for \(name)")
            }
        }
    }
}
