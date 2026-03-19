import Foundation
import XCTest

enum FixtureLoader {
    static func data(named name: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        let bundle = Bundle(for: TestBundleMarker.self)
        guard let url = bundle.url(forResource: name, withExtension: nil) else {
            XCTFail("Fixture \(name) ni bila najdena.", file: file, line: line)
            throw NSError(domain: "FixtureLoader", code: 1)
        }
        return try Data(contentsOf: url)
    }
}

final class TestBundleMarker {}
