import Binary
public import Calendar
public import Calendar_Gregorian

extension RFC_3339 {

    public struct TimeWrapper {
        public let value: Gregorian.DateTime

        internal init(_ value: Gregorian.DateTime) {
            self.value = value
        }
    }
}

extension Calendar::DateTime where Date == Gregorian.Date {

    public var rfc3339: RFC_3339.TimeWrapper {
        RFC_3339.TimeWrapper(self)
    }
}

extension RFC_3339.TimeWrapper {

    public func format(offset: RFC_3339.Offset = .utc, precision: Int? = nil) -> String {
        let dateTime = RFC_3339.DateTime(time: value, offset: offset, precision: precision)
        return dateTime.description
    }
}
