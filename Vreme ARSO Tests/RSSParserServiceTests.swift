import XCTest
@testable import Vreme_ARSO

final class RSSParserServiceTests: XCTestCase {
    func testRSSParserParsesItems() throws {
        let data = try FixtureLoader.data(named: "rss_sample.xml")
        let feed = try RSSParserService().parse(data: data)

        XCTAssertEqual(feed.title, "ARSO napoved")
        XCTAssertEqual(feed.items.count, 1)
        XCTAssertEqual(feed.items.first?.title, "Napoved za Slovenijo")
        XCTAssertEqual(feed.items.first?.description, "Pretežno jasno vreme.")
    }
}
