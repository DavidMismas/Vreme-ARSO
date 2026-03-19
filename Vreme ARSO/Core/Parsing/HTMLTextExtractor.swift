import Foundation

struct HTMLSection: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let body: String
}

struct HTMLArticle: Sendable {
    let title: String
    let issuedAtText: String?
    let sections: [HTMLSection]
    let source: String?
    let publishedText: String?
}

struct HTMLTextExtractor {
    func extractArticle(from data: Data) throws -> HTMLArticle {
        guard let html = String(data: data, encoding: .utf8) else {
            throw ARSOError.parsingFailed("HTML vsebine ni bilo mogoče prebrati.")
        }

        let title = firstMatch(in: html, pattern: "<h1>(.*?)</h1>")?.decodedHTML().strippedHTML() ?? "Besedilo"
        let issuedAt = firstMatch(in: html, pattern: "<i>(.*?)</i>")?.decodedHTML().strippedHTML()
        let sourceMatches = matches(in: html, pattern: "<sup>\\s*(.*?)\\s*</sup>")
            .map { $0.decodedHTML().strippedHTML() }
            .filter { !$0.isEmpty }

        let sections = extractSections(from: html)
        return HTMLArticle(
            title: title,
            issuedAtText: issuedAt,
            sections: sections,
            source: sourceMatches.first,
            publishedText: sourceMatches.dropFirst().first
        )
    }

    func plainText(from data: Data) throws -> String {
        let article = try extractArticle(from: data)
        let bodies = article.sections.map { "\($0.title)\n\($0.body)" }
        return bodies.joined(separator: "\n\n")
    }

    private func extractSections(from html: String) -> [HTMLSection] {
        let pattern = "<h2>(.*?)</h2>(.*?)(?=<h2>|<br\\s*/?>\\s*<sup>|</td>)"
        let results = matchesWithRanges(in: html, pattern: pattern)

        return results.compactMap { result -> HTMLSection? in
            guard result.numberOfRanges >= 3,
                  let titleRange = Range(result.range(at: 1), in: html),
                  let bodyRange = Range(result.range(at: 2), in: html) else {
                return nil
            }

            let title = String(html[titleRange]).decodedHTML().strippedHTML().trimmingCharacters(in: .whitespacesAndNewlines)
            let bodyHTML = String(html[bodyRange])
            let paragraphs = matches(in: bodyHTML, pattern: "<p>(.*?)</p>")
                .map { $0.decodedHTML().strippedHTML().trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let body = paragraphs.joined(separator: "\n\n")
            guard !title.isEmpty else { return nil }
            return HTMLSection(title: title, body: body)
        }
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        matches(in: text, pattern: pattern).first
    }

    private func matches(in text: String, pattern: String) -> [String] {
        matchesWithRanges(in: text, pattern: pattern).compactMap { result in
            guard result.numberOfRanges >= 2,
                  let range = Range(result.range(at: 1), in: text) else {
                return nil
            }
            return String(text[range])
        }
    }

    private func matchesWithRanges(in text: String, pattern: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }

        return regex.matches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )
    }
}

private extension String {
    func strippedHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func decodedHTML() -> String {
        self
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#xA;", with: "\n")
    }
}
