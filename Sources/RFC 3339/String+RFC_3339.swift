extension RFC_3339 {

    public struct StringWrapper {
        public let value: String

        internal init(_ value: String) {
            self.value = value
        }
    }
}

extension String {

    public var rfc3339: RFC_3339.StringWrapper {
        RFC_3339.StringWrapper(self)
    }
}

extension RFC_3339.StringWrapper {

    public func parse() throws(RFC_3339.DateTime.Error) -> RFC_3339.DateTime {
        try RFC_3339.DateTime(value)
    }

    public var isValid: Bool {
        do throws(RFC_3339.DateTime.Error) {
            _ = try parse()
            return true
        } catch {
            return false
        }
    }
}
