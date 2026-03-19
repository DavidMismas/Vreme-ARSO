import XCTest
@testable import Vreme_ARSO

final class HTMLTextExtractorTests: XCTestCase {
    func testExtractorBuildsStructuredSections() throws {
        let data = try FixtureLoader.data(named: "forecast_sample.html")
        let article = try HTMLTextExtractor().extractArticle(from: data)

        XCTAssertEqual(article.title, "Vremenska napoved")
        XCTAssertEqual(article.sections.count, 3)
        XCTAssertEqual(article.sections.first?.title, "NAPOVED ZA SLOVENIJO")
        XCTAssertTrue(article.sections.first?.body.contains("Jutri bo delno oblačno.") == true)
        XCTAssertEqual(article.source, "Vir: Agencija Republike Slovenije za okolje")
    }
}
