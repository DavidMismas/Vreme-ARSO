import Combine
import SwiftUI

struct WarningsView: View {
    let container: AppContainer
    @StateObject private var viewModel: WarningsViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: WarningsViewModel(container: container))
    }

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.items.isEmpty {
                LoadingStateView(title: "Nalagam opozorila …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else {
                ForEach(viewModel.items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(item.severity.color)
                                .frame(width: 10, height: 10)
                            Text(item.title)
                                .font(.headline)
                        }
                        Text(item.area)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(item.body)
                            .font(.subheadline)
                        HStack {
                            Text("Velja od: \(item.validFrom.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka")")
                            Spacer()
                            Text("Do: \(item.validTo.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka")")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Opozorila")
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
    }
}

@MainActor
final class WarningsViewModel: ObservableObject {
    @Published private(set) var items: [WarningItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await container.warningsService.fetchWarnings()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
