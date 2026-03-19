import Combine
import SwiftUI
import UIKit

struct ForecastTextView: View {
    let container: AppContainer
    @StateObject private var viewModel: ForecastTextViewModel
    @State private var expandedTypes: Set<ForecastTextSectionType> = [.napoved]
    @State private var hasConfiguredDefaultExpansion = false

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: ForecastTextViewModel(container: container))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sections.isEmpty {
                    LoadingStateView(title: "Nalagam napoved …")
                } else if let errorMessage = viewModel.errorMessage, viewModel.sections.isEmpty {
                    ErrorStateView(message: errorMessage) {
                        Task {
                            await viewModel.load()
                            configureDefaultExpansionIfNeeded()
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let latestIssuedAt = viewModel.latestIssuedAt {
                                Text("Zadnja objava: \(DateFormatterSI.displayDateTime.string(from: latestIssuedAt))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(viewModel.orderedSections) { section in
                                DisclosureGroup(
                                    isExpanded: binding(for: section.type),
                                    content: {
                                        VStack(alignment: .leading, spacing: 14) {
                                            if let issuedAt = section.issuedAt {
                                                Text("Objavljeno \(DateFormatterSI.displayDateTime.string(from: issuedAt))")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Text(section.body)
                                                .font(.body)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .textSelection(.enabled)
                                        }
                                        .padding(.top, 12)
                                    },
                                    label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(section.title)
                                                .font(.title3.weight(.semibold))
                                                .foregroundStyle(.primary)
                                                .multilineTextAlignment(.leading)

                                            Text(section.type.naslov)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                )
                                .tint(AppTheme.Colors.accent)
                                .padding(18)
                                .background(AppTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }

                            HStack {
                                SourceBadge()
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
            }
            .navigationTitle("Tekstovna napoved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        if !viewModel.combinedBody.isEmpty {
                            UIPasteboard.general.string = viewModel.combinedBody
                        }
                    } label: {
                        Label("Kopiraj", systemImage: "doc.on.doc")
                    }

                    Button {
                        Task {
                            await viewModel.load()
                            configureDefaultExpansionIfNeeded()
                        }
                    } label: {
                        Label("Osveži", systemImage: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.load()
                configureDefaultExpansionIfNeeded()
            }
        }
    }

    private func binding(for type: ForecastTextSectionType) -> Binding<Bool> {
        Binding(
            get: { expandedTypes.contains(type) },
            set: { isExpanded in
                if isExpanded {
                    expandedTypes.insert(type)
                } else {
                    expandedTypes.remove(type)
                }
            }
        )
    }

    private func configureDefaultExpansionIfNeeded() {
        guard !hasConfiguredDefaultExpansion else { return }
        var defaults: Set<ForecastTextSectionType> = [.napoved]
        if viewModel.section(for: .opozorilo) != nil {
            defaults.insert(.opozorilo)
        }
        expandedTypes = defaults
        hasConfiguredDefaultExpansion = true
    }
}

@MainActor
final class ForecastTextViewModel: ObservableObject {
    @Published private(set) var sections: [ForecastTextSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func section(for type: ForecastTextSectionType) -> ForecastTextSection? {
        sections.first(where: { $0.type == type })
    }

    var orderedSections: [ForecastTextSection] {
        ForecastTextSectionType.allCases.compactMap(section(for:))
    }

    var latestIssuedAt: Date? {
        sections.compactMap(\.issuedAt).max()
    }

    var combinedBody: String {
        orderedSections
            .map { "\($0.title)\n\n\($0.body)" }
            .joined(separator: "\n\n")
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sections = try await container.forecastTextService.fetchSections()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
