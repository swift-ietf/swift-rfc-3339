extension RFC_3339 {

    public enum Validation {}
}

extension RFC_3339.Validation {

    public static func validateLeapSecond(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        offsetSeconds: Int
    ) throws(RFC_3339.DateTime.Error) {

        var utcYear = year
        var utcMonth = month
        var utcDay = day
        var minutesOfDay = hour * 60 + minute - offsetSeconds / 60

        if minutesOfDay < 0 {
            minutesOfDay += 24 * 60
            utcDay -= 1
            if utcDay < 1 {
                utcMonth -= 1
                if utcMonth < 1 {
                    utcMonth = 12
                    utcYear -= 1
                }
                utcDay = daysIn(month: utcMonth, year: utcYear)
            }
        } else if minutesOfDay >= 24 * 60 {
            minutesOfDay -= 24 * 60
            utcDay += 1
            if utcDay > daysIn(month: utcMonth, year: utcYear) {
                utcDay = 1
                utcMonth += 1
                if utcMonth > 12 {
                    utcMonth = 1
                    utcYear += 1
                }
            }
        }

        let utcHour = minutesOfDay / 60
        let utcMinute = minutesOfDay % 60

        let isLeapSecondInstant =
            utcHour == 23 && utcMinute == 59
            && ((utcMonth == 6 && utcDay == 30) || (utcMonth == 12 && utcDay == 31))

        guard isLeapSecondInstant else {
            throw RFC_3339.DateTime.Error.invalidLeapSecond(month: utcMonth, day: utcDay)
        }
    }

    private static func daysIn(month: Int, year: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: return 31

        case 4, 6, 9, 11: return 30

        default:
            let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
            return isLeap ? 29 : 28
        }
    }
}
