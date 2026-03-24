import SwiftUI
import UIKit

enum AppTheme {
    enum Palette {
        static let skyBlue = UIColor(hex: "#8FD0F5")
        static let mintGreen = UIColor(hex: "#9BD8A5")
        static let canvas = UIColor(hex: "#152229")
        static let canvasAlt = UIColor(hex: "#1B2A2F")
        static let surface = UIColor(hex: "#233842")
        static let surfaceMuted = UIColor(hex: "#35515B")
        static let surfaceSoft = UIColor(hex: "#476055")
        static let border = UIColor(hex: "#8FAAA8")
        static let textPrimary = UIColor(hex: "#F2F6F4")
        static let textSecondary = UIColor(hex: "#B6C4C6")
    }

    enum Colors {
        static let accent = Color(uiColor: Palette.skyBlue)
        static let accentSecondary = Color(uiColor: Palette.mintGreen)
        static let screenBackground = Color(uiColor: Palette.canvas)
        static let cardBackground = Color(uiColor: Palette.surface)
        static let groupedBackground = Color(uiColor: Palette.surfaceSoft)
        static let sectionTint = Color(uiColor: Palette.surfaceMuted)
        static let badgeBackground = Color(uiColor: Palette.surfaceMuted)
        static let border = Color(uiColor: Palette.border)
        static let mapPanelBackground = LinearGradient(
            colors: [
                Color(uiColor: Palette.surface).opacity(0.98),
                Color(uiColor: Palette.surfaceMuted).opacity(0.94),
                Color(uiColor: Palette.surfaceSoft).opacity(0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let cardGradient = LinearGradient(
            colors: [
                Color(uiColor: Palette.surface),
                Color(uiColor: Palette.surfaceSoft).opacity(0.88),
                Color(uiColor: Palette.border).opacity(0.34)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let mapAnnotationBackground = Color(uiColor: Palette.surfaceMuted).opacity(0.96)
        static let mapAnnotationLabelBackground = Color(uiColor: Palette.canvasAlt).opacity(0.96)
        static let warningMinor = Color(red: 0.31, green: 0.68, blue: 0.44)
        static let warningModerate = Color(red: 0.89, green: 0.69, blue: 0.22)
        static let warningSevere = Color(red: 0.90, green: 0.48, blue: 0.24)
        static let warningExtreme = Color(red: 0.83, green: 0.27, blue: 0.21)

        static let screenGradient = LinearGradient(
            colors: [
                Color(uiColor: Palette.canvas),
                Color(uiColor: Palette.canvasAlt),
                Color(uiColor: Palette.surfaceSoft).opacity(0.90),
                Color(uiColor: Palette.surfaceMuted).opacity(0.76)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Metrics {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 16
    }

    static func configureAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = Palette.canvas
        navigationAppearance.shadowColor = Palette.border
        navigationAppearance.largeTitleTextAttributes = [
            .foregroundColor: Palette.textPrimary
        ]
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: Palette.textPrimary
        ]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = Palette.skyBlue

    }
}

extension View {
    func appScreenBackground() -> some View {
        background(AppTheme.Colors.screenGradient.ignoresSafeArea())
    }

    func appTabBarStyle() -> some View {
        toolbarBackground(AppTheme.Colors.cardBackground.opacity(0.98), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }

    func appListStyle() -> some View {
        scrollContentBackground(.hidden)
            .background(AppTheme.Colors.screenGradient.ignoresSafeArea())
            .listStyle(.insetGrouped)
            .listRowBackground(AppTheme.Colors.sectionTint.opacity(0.32))
            .listRowSeparatorTint(AppTheme.Colors.border.opacity(0.9))
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

private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        let value = Int(cleaned, radix: 16) ?? 0
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
