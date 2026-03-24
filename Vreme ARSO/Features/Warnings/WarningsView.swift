import Combine
import SwiftUI

struct WarningsView: View {
    let container: AppContainer
    @StateObject private var viewModel: WarningsViewModel
    @State private var expandedRegions: Set<String> = []

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: WarningsViewModel(container: container))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.items.isEmpty {
                LoadingStateView(title: "Nalagam opozorila …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.groupedItems) { group in
                        WarningRegionAccordionCard(
                            group: group,
                            isExpanded: expandedRegions.contains(group.id),
                            toggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedRegions.contains(group.id) {
                                        expandedRegions.remove(group.id)
                                    } else {
                                        expandedRegions.insert(group.id)
                                    }
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Opozorila")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
        .appScreenBackground()
    }
}

private struct WarningRegionAccordionCard: View {
    let group: WarningRegionGroup
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggle) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accent.opacity(0.14))
                            .frame(width: 44, height: 44)

                        Image(systemName: group.systemImage)
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(group.countText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.screenBackground.opacity(0.88))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.18), value: isExpanded)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        WarningCardRow(item: item)

                        if index < group.items.count - 1 {
                            Divider()
                                .overlay(AppTheme.Colors.border.opacity(0.55))
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(AppTheme.Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.Colors.cardGradient,
            in: RoundedRectangle(cornerRadius: AppTheme.Metrics.cardCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Metrics.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.Colors.border.opacity(0.95), lineWidth: 1)
        }
        .shadow(color: AppTheme.Colors.accent.opacity(0.10), radius: 14, y: 7)
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
    }
}

private struct WarningCardRow: View {
    let item: WarningItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(item.severity.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)

                    Text(item.severityDescription)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(item.severity.color)
                }
            }

            Text(item.body)
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Velja od")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.validFromText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Do")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.validToText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
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

    fileprivate var groupedItems: [WarningRegionGroup] {
        Dictionary(grouping: items, by: \.regionGroup)
            .map { key, value in
                WarningRegionGroup(
                    region: key,
                    items: value.sorted {
                        if $0.severity != $1.severity {
                            return $0.severity > $1.severity
                        }
                        return ($0.validFrom ?? .distantPast) > ($1.validFrom ?? .distantPast)
                    }
                )
            }
            .sorted { $0.region.sortOrder < $1.region.sortOrder }
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

private struct WarningRegionGroup: Identifiable {
    let region: WarningRegion
    let items: [WarningItem]

    var id: String { region.rawValue }
    var title: String { region.title }
    var systemImage: String { region.systemImage }
    var countText: String {
        let count = items.count
        if count == 1 {
            return "1 opozorilo"
        } else if count == 2 {
            return "2 opozorili"
        } else if count == 3 || count == 4 {
            return "\(count) opozorila"
        } else {
            return "\(count) opozoril"
        }
    }
}

private enum WarningRegion: String {
    case wholeSlovenia
    case northWest
    case northEast
    case central
    case southWest
    case southEast
    case other

    var title: String {
        switch self {
        case .wholeSlovenia: return "Vsa Slovenija"
        case .northWest: return "Severozahod"
        case .northEast: return "Severovzhod"
        case .central: return "Osrednja Slovenija"
        case .southWest: return "Jugozahod"
        case .southEast: return "Jugovzhod"
        case .other: return "Druga območja"
        }
    }

    var systemImage: String {
        switch self {
        case .wholeSlovenia:
            return "map"
        case .northWest, .northEast, .central, .southWest, .southEast:
            return "map.fill"
        case .other:
            return "location"
        }
    }

    var sortOrder: Int {
        switch self {
        case .wholeSlovenia: return 0
        case .northWest: return 1
        case .northEast: return 2
        case .central: return 3
        case .southWest: return 4
        case .southEast: return 5
        case .other: return 6
        }
    }
}

private extension WarningItem {
    var regionGroup: WarningRegion {
        let normalized = area
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "sl_SI"))
            .lowercased()

        if normalized.contains("cela slovenija") || normalized == "slovenija" || normalized.contains("vsa slovenija") {
            return .wholeSlovenia
        }
        if normalized.contains("severozahod") || normalized.contains("north-west") {
            return .northWest
        }
        if normalized.contains("severovzhod") || normalized.contains("north-east") {
            return .northEast
        }
        if normalized.contains("osrednj") || normalized.contains("middle") {
            return .central
        }
        if normalized.contains("jugozahod") || normalized.contains("south-west") {
            return .southWest
        }
        if normalized.contains("jugovzhod") || normalized.contains("south-east") {
            return .southEast
        }
        return .other
    }

    var validFromText: String {
        validFrom.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka"
    }

    var validToText: String {
        validTo.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka"
    }

    var severityDescription: String {
        switch severity {
        case .minor:
            return "Manjša ogroženost"
        case .moderate:
            return "Zmerna ogroženost"
        case .severe:
            return "Velika ogroženost"
        case .extreme:
            return "Zelo velika ogroženost"
        case .unknown:
            return "Stopnja ni določena"
        }
    }
}
