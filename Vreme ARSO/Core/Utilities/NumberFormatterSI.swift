import Foundation

enum NumberFormatterSI {
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static func string(from value: Double?, suffix: String? = nil) -> String {
        guard let value else { return "Ni podatka" }
        let base = decimal.string(from: NSNumber(value: value)) ?? "\(value)"
        if let suffix {
            return "\(base) \(suffix)"
        }
        return base
    }
}
