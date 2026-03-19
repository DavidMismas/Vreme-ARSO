import Foundation

struct ARSOForecastTextService {
    let apiClient: APIClientProtocol
    let htmlExtractor: HTMLTextExtractor

    func fetchSections() async throws -> [ForecastTextSection] {
        async let overview = fetchArticle(endpoint: .forecastTextOverview)
        async let forecast = fetchArticle(endpoint: .forecastTodayTomorrow)
        async let warning = fetchArticle(endpoint: .warningText)
        async let outlook = fetchArticle(endpoint: .forecastOutlook)
        async let longRange = fetchArticle(endpoint: .forecastLongRange)
        async let neighbours = fetchArticle(endpoint: .forecastNeighbours)
        async let synoptic = fetchArticle(endpoint: .forecastSynoptic)

        let overviewArticle = try await overview
        let forecastArticle = try await forecast
        let warningArticle = try await warning
        let outlookArticle = try await outlook
        let longRangeArticle = try await longRange
        let neighboursArticle = try await neighbours
        let synopticArticle = try await synoptic

        let forecastSection = makeSection(
            type: .napoved,
            fallbackArticle: overviewArticle,
            preferredArticle: forecastArticle,
            headingHints: ["NAPOVED ZA SLOVENIJO"],
            endpoint: .forecastTodayTomorrow
        )
        let warningSection = makeSection(
            type: .opozorilo,
            fallbackArticle: overviewArticle,
            preferredArticle: warningArticle,
            headingHints: ["OPOZORILO"],
            endpoint: .warningText
        )
        let outlookSection = makeSection(
            type: .obeti,
            fallbackArticle: overviewArticle,
            preferredArticle: outlookArticle,
            headingHints: ["OBETI"],
            endpoint: .forecastOutlook
        )
        let longRangeSection = makeSection(
            type: .petDoDesetDni,
            fallbackArticle: overviewArticle,
            preferredArticle: longRangeArticle,
            headingHints: ["OBETI", "OD 5 DO 10 DNI"],
            endpoint: .forecastLongRange
        )
        let neighboursSection = makeSection(
            type: .sosednjePokrajine,
            fallbackArticle: overviewArticle,
            preferredArticle: neighboursArticle,
            headingHints: ["NAPOVED ZA SOSEDNJE POKRAJINE"],
            endpoint: .forecastNeighbours
        )
        let synopticSection = makeSection(
            type: .vremenskaSlika,
            fallbackArticle: overviewArticle,
            preferredArticle: synopticArticle,
            headingHints: ["VREMENSKA SLIKA"],
            endpoint: .forecastSynoptic
        )

        let combinedBody = [forecastSection, warningSection, outlookSection, longRangeSection, neighboursSection, synopticSection]
            .map { "\($0.title)\n\n\($0.body)" }
            .joined(separator: "\n\n")

        let fullTextSection = ForecastTextSection(
            id: ForecastTextSectionType.celoBesedilo.rawValue,
            type: .celoBesedilo,
            title: ForecastTextSectionType.celoBesedilo.naslov,
            body: combinedBody,
            issuedAt: forecastSection.issuedAt ?? overviewArticle.publishedText.flatMap(DateFormatterSI.parseHTMLPublished),
            sourceURL: Endpoint.forecastTextOverview.url
        )

        return [
            forecastSection,
            warningSection,
            outlookSection,
            longRangeSection,
            neighboursSection,
            synopticSection,
            fullTextSection
        ]
    }

    private func fetchArticle(endpoint: Endpoint) async throws -> HTMLArticle {
        let data = try await apiClient.data(for: endpoint)
        return try htmlExtractor.extractArticle(from: data)
    }

    private func makeSection(
        type: ForecastTextSectionType,
        fallbackArticle: HTMLArticle,
        preferredArticle: HTMLArticle,
        headingHints: [String],
        endpoint: Endpoint
    ) -> ForecastTextSection {
        let preferredSection = preferredArticle.sections.first(where: { section in
            headingHints.contains(where: { section.title.localizedCaseInsensitiveContains($0) })
        }) ?? preferredArticle.sections.first

        let fallbackSection = fallbackArticle.sections.first(where: { section in
            headingHints.contains(where: { section.title.localizedCaseInsensitiveContains($0) })
        })

        let chosenSection = preferredSection ?? fallbackSection
        let issuedAt = preferredArticle.publishedText.flatMap(DateFormatterSI.parseHTMLPublished)
            ?? fallbackArticle.publishedText.flatMap(DateFormatterSI.parseHTMLPublished)

        return ForecastTextSection(
            id: type.rawValue,
            type: type,
            title: type.naslov,
            body: chosenSection?.body ?? "Podatki trenutno niso na voljo.",
            issuedAt: issuedAt,
            sourceURL: endpoint.url
        )
    }
}
