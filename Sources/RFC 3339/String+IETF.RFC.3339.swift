extension IETF.RFC.`3339` {

    public struct StringWrapper {
        public let value: String

        internal init(_ value: String) {
            self.value = value
        }
    }
}

extension String {

    public var rfc3339: IETF.RFC.`3339`.StringWrapper {
        IETF.RFC.`3339`.StringWrapper(self)
    }
}

extension IETF.RFC.`3339`.StringWrapper {

    public func parse() throws(IETF.RFC.`3339`.DateTime.Error) -> IETF.RFC.`3339`.DateTime {
        try IETF.RFC.`3339`.DateTime(value)
    }

    public var isValid: Bool {
        do throws(IETF.RFC.`3339`.DateTime.Error) {
            _ = try parse()
            return true
        } catch {
            return false
        }
    }
}
