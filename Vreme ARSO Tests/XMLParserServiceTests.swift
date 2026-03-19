import XCTest
@testable import Vreme_ARSO

final class XMLParserServiceTests: XCTestCase {
    func testXMLParserParsesObservationRoot() throws {
        let data = try FixtureLoader.data(named: "observation_sample.xml")
        let root = try XMLParserService().parse(data: data)

        XCTAssertEqual(root.name, "data")
        XCTAssertEqual(root.children(named: "metData").count, 2)
        XCTAssertEqual(root.textValue(forChild: "credit"), "Agencija Republike Slovenije za okolje")
    }
}
