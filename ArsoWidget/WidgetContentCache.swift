import Foundation

actor WidgetContentCache {
    static let shared = WidgetContentCache()

    private var entries: [String: CachedWidgetContent] = [:]

    func content(for key: String, maxAge: TimeInterval) -> WidgetWeatherContent? {
        guard
            let entry = entries[key],
            Date().timeIntervalSince(entry.storedAt) < maxAge
        else {
            return nil
        }

        return entry.content
    }

    func store(_ content: WidgetWeatherContent, for key: String) {
        entries[key] = CachedWidgetContent(content: content, storedAt: Date())
    }
}

private struct CachedWidgetContent {
    let content: WidgetWeatherContent
    let storedAt: Date
}
