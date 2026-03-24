import SwiftUI

struct SourceBadge: View {
    var body: some View {
        Text("Vir podatkov: ARSO")
            .font(.caption)
            .foregroundStyle(AppTheme.Colors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.Colors.badgeBackground.opacity(0.95), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(AppTheme.Colors.accent.opacity(0.22), lineWidth: 1)
            }
            .accessibilityLabel("Vir podatkov: ARSO")
    }
}
