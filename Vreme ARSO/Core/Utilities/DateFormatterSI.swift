import Foundation

enum DateFormatterSI {
    static let arsoXMLWithZone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "dd.MM.yyyy H:mm z"
        return formatter
    }()

    static let arsoXMLWithoutZone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "dd.MM.yyyy H:mm"
        return formatter
    }()

    static let htmlPublished: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    static let cap: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
        return formatter
    }()

    static let capWithoutFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return formatter
    }()

    static let rss: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let displayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func parseCAP(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return cap.date(from: string) ?? capWithoutFraction.date(from: string)
    }

    static func parseARSODate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        if let parsed = arsoXMLWithZone.date(from: string) {
            return parsed
        }

        let withoutZone = string
            .replacingOccurrences(of: " CET", with: "")
            .replacingOccurrences(of: " CEST", with: "")
            .replacingOccurrences(of: " UTC", with: "")

        return arsoXMLWithoutZone.date(from: withoutZone)
    }

    static func parseHTMLPublished(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return htmlPublished.date(from: string)
    }
}
