import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryTitle: String
    let action: (() -> Void)?

    init(title: String = "Prišlo je do napake", message: String, retryTitle: String = "Poskusi znova", action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.action = action
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            if let action {
                Button(retryTitle, action: action)
            }
        }
        .tint(AppTheme.Colors.accent)
        .appScreenBackground()
    }
}
