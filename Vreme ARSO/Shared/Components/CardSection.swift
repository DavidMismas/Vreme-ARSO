import SwiftUI

struct CardSection<Content: View>: View {
    let title: String
    let systemImage: String?
    @ViewBuilder let content: Content

    init(title: String, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding(AppTheme.Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.Metrics.cardCornerRadius, style: .continuous))
    }
}
