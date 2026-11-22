import Binary
public import Calendar
public import Calendar_Gregorian

extension IETF.RFC.`3339` {

    public struct TimeWrapper {
        public let value: Gregorian.DateTime

        internal init(_ value: Gregorian.DateTime) {
            self.value = value
        }
    }
}

extension Calendar::DateTime where Date == Gregorian.Date {

    public var rfc3339: IETF.RFC.`3339`.TimeWrapper {
        IETF.RFC.`3339`.TimeWrapper(self)
    }
}

extension IETF.RFC.`3339`.TimeWrapper {

    public func format(offset: IETF.RFC.`3339`.Offset = .utc, precision: Int? = nil) -> String {
        let dateTime = IETF.RFC.`3339`.DateTime(time: value, offset: offset, precision: precision)
        return dateTime.description
    }
}
