import XCTest
@testable import Vreme_ARSO

final class AutoRefreshIntervalTests: XCTestCase {
    func testRefreshBecomesDueExactlyAtSelectedInterval() {
        let lastUpdate = Date(timeIntervalSince1970: 1_000)
        for interval in AutoRefreshInterval.allCases {
            XCTAssertFalse(interval.isDue(lastUpdate: lastUpdate, now: lastUpdate.addingTimeInterval(interval.seconds - 1)))
            XCTAssertTrue(interval.isDue(lastUpdate: lastUpdate, now: lastUpdate.addingTimeInterval(interval.seconds)))
            XCTAssertTrue(interval.isDue(lastUpdate: lastUpdate, now: lastUpdate.addingTimeInterval(interval.seconds + 1)))
        }
    }

    func testMissingDataNeedsInitialRefresh() {
        XCTAssertTrue(AutoRefreshInterval.everySixHours.isDue(lastUpdate: nil))
    }

    func testOnlyRequestedIntervalsAreSupported() {
        XCTAssertEqual(AutoRefreshInterval.allCases.map(\.seconds), [3600, 10800, 21600])
        XCTAssertNil(AutoRefreshInterval(rawValue: 2))
    }
}
