import SwiftUI

struct SourceBadge: View {
    var body: some View {
        Text("Vir podatkov: ARSO")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.08), in: Capsule())
            .accessibilityLabel("Vir podatkov: ARSO")
    }
}
