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
}
