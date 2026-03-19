import SwiftUI

struct HomeSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
                    .frame(height: 210)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 12) {
                            RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.15)).frame(width: 120, height: 18)
                            RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.18)).frame(width: 220, height: 56)
                            RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.15)).frame(width: 180, height: 20)
                        }
                        .padding(24)
                    }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.Colors.cardBackground)
                            .frame(height: 82)
                    }
                }

                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppTheme.Colors.cardBackground)
                        .frame(height: 124)
                }
            }
            .padding()
            .redacted(reason: .placeholder)
        }
        .scrollIndicators(.hidden)
    }
}
