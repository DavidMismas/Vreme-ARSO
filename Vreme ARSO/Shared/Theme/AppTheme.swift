import SwiftUI

enum AppTheme {
    enum Colors {
        static let accent = Color(red: 0.10, green: 0.36, blue: 0.62)
        static let cardBackground = Color(uiColor: .secondarySystemBackground)
        static let groupedBackground = Color(uiColor: .systemGroupedBackground)
        static let warningMinor = Color(red: 0.25, green: 0.55, blue: 0.32)
        static let warningModerate = Color(red: 0.80, green: 0.58, blue: 0.12)
        static let warningSevere = Color(red: 0.79, green: 0.34, blue: 0.16)
        static let warningExtreme = Color(red: 0.64, green: 0.16, blue: 0.14)
    }

    enum Metrics {
        static let cardCornerRadius: CGFloat = 18
        static let cardPadding: CGFloat = 16
    }
}

extension WarningSeverity {
    var color: Color {
        switch self {
        case .minor:
            return AppTheme.Colors.warningMinor
        case .moderate:
            return AppTheme.Colors.warningModerate
        case .severe:
            return AppTheme.Colors.warningSevere
        case .extreme:
            return AppTheme.Colors.warningExtreme
        case .unknown:
            return .secondary
        }
    }
}
