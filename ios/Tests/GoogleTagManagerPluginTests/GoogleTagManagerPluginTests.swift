import XCTest
@testable import GoogleTagManagerPlugin

class GoogleTagManagerTests: XCTestCase {
    func testGTMManagerInitializes() {
        let manager = GTMManager()
        XCTAssertNotNil(manager)
    }

    func testParameterSanitizerNormalizesEventNames() {
        XCTAssertEqual(GTMParameterSanitizer.eventName("purchase-complete!"), "purchase_complete_")
    }

    func testParameterSanitizerConvertsUserPropertyValues() {
        XCTAssertEqual(GTMParameterSanitizer.stringValue(true), "true")
        XCTAssertEqual(GTMParameterSanitizer.stringValue(42), "42")
    }

    func testDataLayerLookupMatchesWebSearchOrder() {
        let entries: [[String: Any]] = [
            ["currency": "USD"],
            ["event": "purchase"],
            ["currency": "EUR"],
        ]

        XCTAssertEqual(DataLayerLookup.latestValue(in: entries, for: "currency") as? String, "EUR")
        XCTAssertEqual(DataLayerLookup.latestValue(in: entries, for: "event") as? String, "purchase")
        XCTAssertNil(DataLayerLookup.latestValue(in: entries, for: "missing"))
    }
}
