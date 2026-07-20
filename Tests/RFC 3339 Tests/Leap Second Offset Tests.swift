// Leap Second Offset Tests.swift
// swift-rfc-3339
//
// Regression tests for fable-448 F-001: leap-second validation must be
// evaluated against the UTC instant (offset- and time-of-day-aware),
// not the local calendar date alone.

import Testing

@testable import RFC_3339

extension RFC_3339.DateTime.Test {
    @Suite
    struct `Leap Second Offset` {
        @Test
        func `RFC 5,8 example west-offset leap second parses`() throws {
            // RFC 3339 Section 5.8: 1990-12-31T15:59:60-08:00 is the same
            // leap-second instant as 1990-12-31T23:59:60Z.
            let dt = try RFC_3339.DateTime("1990-12-31T15:59:60-08:00")
            #expect(dt.time.second.value == 60)
            #expect(dt.offset.seconds == -8 * 3600)
        }

        @Test
        func `East-offset leap second on local January 1 parses`() throws {
            // UTC instant is 1990-12-31T23:59:60Z — a real leap second —
            // even though the local calendar date is January 1.
            let dt = try RFC_3339.DateTime("1991-01-01T00:59:60+01:00")
            #expect(dt.time.second.value == 60)
            #expect(dt.time.month == 1)
            #expect(dt.time.day == 1)
        }

        @Test
        func `East-offset leap second on local July 1 parses`() throws {
            // UTC instant is 2015-06-30T23:59:60Z.
            let dt = try RFC_3339.DateTime("2015-07-01T08:59:60+09:00")
            #expect(dt.time.second.value == 60)
        }

        @Test
        func `Leap second at wrong UTC time of day is rejected`() throws {
            // December 31, but 12:00:60Z is not 23:59:60 UTC — impossible instant.
            #expect(throws: RFC_3339.DateTime.Error.self) {
                _ = try RFC_3339.DateTime("1990-12-31T12:00:60Z")
            }
        }

        @Test
        func `Local December 31 leap second at wrong UTC instant is rejected`() throws {
            // Local date/time is 23:59:60 on December 31, but with +09:00 the
            // UTC instant is 14:59:60Z — impossible.
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
